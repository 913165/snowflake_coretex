-- =============================================================
-- Audio Transcription Workflow with Speaker Detection
-- =============================================================

-- 1. Stage setup (SSE encryption required for AI_TRANSCRIBE)
CREATE OR REPLACE STAGE ANALYTICS_DB.PUBLIC.AUDIO_STAGE
  DIRECTORY = ( ENABLE = true )
  ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );

-- 2. Upload audio from workspace to stage
COPY FILES INTO @ANALYTICS_DB.PUBLIC.AUDIO_STAGE
FROM 'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live'
FILES=('audios/call_center_audio_001.mp3');

-- 3. Table for storing transcriptions as JSON
CREATE TABLE IF NOT EXISTS ANALYTICS_DB.PUBLIC.CALL_TRANSCRIPTIONS (
    call_id VARCHAR DEFAULT UUID_STRING(),
    audio_file VARCHAR,
    transcription VARIANT,
    transcribed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 4. Transcribe with speaker detection and store as JSON
INSERT INTO ANALYTICS_DB.PUBLIC.CALL_TRANSCRIPTIONS (audio_file, transcription)
SELECT 
    'audios/call_center_audio_001.mp3',
    AI_TRANSCRIBE(
        TO_FILE('@ANALYTICS_DB.PUBLIC.AUDIO_STAGE', 'audios/call_center_audio_001.mp3'),
        {'timestamp_granularity': 'speaker'}
    );

-- 5. View full transcription metadata
SELECT 
    call_id,
    audio_file,
    transcription:audio_duration::FLOAT AS audio_duration_sec,
    ARRAY_SIZE(transcription:segments) AS total_segments,
    transcribed_at
FROM ANALYTICS_DB.PUBLIC.CALL_TRANSCRIPTIONS;

-- 6. View speaker interaction timeline
SELECT 
    call_id,
    seg.value:speaker_label::VARCHAR AS speaker,
    seg.value:start::FLOAT AS start_time,
    seg.value:end::FLOAT AS end_time,
    seg.value:text::VARCHAR AS text
FROM ANALYTICS_DB.PUBLIC.CALL_TRANSCRIPTIONS,
    LATERAL FLATTEN(input => transcription:segments) seg
ORDER BY seg.value:start::FLOAT;

-- 7. Extract structured interaction JSON per speaker for classification
SELECT 
    call_id,
    audio_file,
    transcription:audio_duration::FLOAT AS audio_duration_sec,
    transcription AS full_transcription_json,
    ARRAY_AGG(
        OBJECT_CONSTRUCT(
            'speaker', seg.value:speaker_label::VARCHAR,
            'start', seg.value:start::FLOAT,
            'end', seg.value:end::FLOAT,
            'text', seg.value:text::VARCHAR
        )
    ) WITHIN GROUP (ORDER BY seg.value:start::FLOAT) AS speaker_interactions_json
FROM ANALYTICS_DB.PUBLIC.CALL_TRANSCRIPTIONS,
    LATERAL FLATTEN(input => transcription:segments) seg
GROUP BY call_id, audio_file, transcription;

-- =============================================================
-- Sentiment & Intent Extraction for Quality Scoring
-- =============================================================

-- 8. Extract sentiment and intent per speaker segment
CREATE OR REPLACE TABLE ANALYTICS_DB.PUBLIC.CALL_QUALITY_SCORES AS
WITH segments AS (
    SELECT 
        call_id,
        audio_file,
        seg.index AS segment_index,
        seg.value:speaker_label::VARCHAR AS speaker,
        seg.value:start::FLOAT AS start_time,
        seg.value:end::FLOAT AS end_time,
        seg.value:text::VARCHAR AS text
    FROM ANALYTICS_DB.PUBLIC.CALL_TRANSCRIPTIONS,
        LATERAL FLATTEN(input => transcription:segments) seg
),
enriched AS (
    SELECT 
        *,
        AI_SENTIMENT(text) AS sentiment_raw,
        AI_CLASSIFY(
            text,
            ['greeting', 'inquiry', 'complaint', 'verification', 'resolution', 'empathy', 'closing', 'acknowledgment', 'escalation', 'hold_request']
        ) AS intent_raw
    FROM segments
)
SELECT 
    call_id,
    audio_file,
    segment_index,
    speaker,
    start_time,
    end_time,
    text,
    sentiment_raw:categories[0]:sentiment::VARCHAR AS sentiment,
    CASE sentiment_raw:categories[0]:sentiment::VARCHAR
        WHEN 'positive' THEN 1
        WHEN 'neutral' THEN 0
        WHEN 'negative' THEN -1
        ELSE 0
    END AS sentiment_score,
    intent_raw:labels[0]::VARCHAR AS intent,
    sentiment_raw AS sentiment_detail,
    intent_raw AS intent_detail
FROM enriched
ORDER BY start_time;

-- 9. Quality scoring summary per call
CREATE OR REPLACE VIEW ANALYTICS_DB.PUBLIC.CALL_QUALITY_SUMMARY AS
WITH agent_metrics AS (
    SELECT 
        call_id,
        audio_file,
        AVG(sentiment_score) AS agent_avg_sentiment,
        COUNT_IF(intent IN ('empathy', 'resolution')) AS empathy_resolution_count,
        COUNT_IF(intent = 'greeting') AS greeting_count,
        COUNT_IF(intent = 'closing') AS closing_count,
        COUNT(*) AS agent_segment_count
    FROM ANALYTICS_DB.PUBLIC.CALL_QUALITY_SCORES
    WHERE speaker = 'SPEAKER_01'
    GROUP BY call_id, audio_file
),
customer_metrics AS (
    SELECT 
        call_id,
        AVG(sentiment_score) AS customer_avg_sentiment,
        COUNT_IF(intent = 'complaint') AS complaint_count,
        COUNT_IF(intent = 'escalation') AS escalation_count,
        COUNT(*) AS customer_segment_count
    FROM ANALYTICS_DB.PUBLIC.CALL_QUALITY_SCORES
    WHERE speaker = 'SPEAKER_00'
    GROUP BY call_id
)
SELECT 
    a.call_id,
    a.audio_file,
    ROUND(a.agent_avg_sentiment, 2) AS agent_avg_sentiment,
    ROUND(c.customer_avg_sentiment, 2) AS customer_avg_sentiment,
    a.empathy_resolution_count,
    a.greeting_count,
    a.closing_count,
    c.complaint_count,
    c.escalation_count,
    a.agent_segment_count,
    c.customer_segment_count,
    ROUND(
        (GREATEST(a.agent_avg_sentiment + 1, 0) / 2.0 * 25) +
        (LEAST(a.empathy_resolution_count, 5) / 5.0 * 25) +
        (LEAST(a.greeting_count, 1) * 15) +
        (LEAST(a.closing_count, 1) * 10) +
        (GREATEST(c.customer_avg_sentiment + 1, 0) / 2.0 * 25),
    2) AS quality_score
FROM agent_metrics a
JOIN customer_metrics c ON a.call_id = c.call_id;

-- 10. View segment-level detail
SELECT speaker, start_time, text, sentiment, sentiment_score, intent
FROM ANALYTICS_DB.PUBLIC.CALL_QUALITY_SCORES
ORDER BY start_time;

-- 11. View call quality summary
SELECT * FROM ANALYTICS_DB.PUBLIC.CALL_QUALITY_SUMMARY;
