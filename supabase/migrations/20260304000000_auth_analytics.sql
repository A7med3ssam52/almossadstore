-- Create auth_analytics table
CREATE TABLE IF NOT EXISTS public.auth_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL,
    step_name TEXT NOT NULL,
    event_type TEXT NOT NULL, -- "STEP_VIEW", "STEP_COMPLETE", "BACK_CLICK"
    path TEXT NOT NULL, -- "/login" or "/signup"
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Enable RLS
ALTER TABLE public.auth_analytics ENABLE ROW LEVEL SECURITY;

-- Allow anonymous inserts for analytics
CREATE POLICY "Allow anonymous inserts" ON public.auth_analytics
    FOR INSERT TO anon
    WITH CHECK (true);

-- Allow authenticated users to insert too
CREATE POLICY "Allow authenticated inserts" ON public.auth_analytics
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- Add comments
COMMENT ON TABLE public.auth_analytics IS 'Tracks user progress through the story-based authentication flow.';
