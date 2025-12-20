import { createClient } from '@supabase/supabase-js';

/**
 * Get Supabase client with lazy initialization.
 * This prevents build-time errors when environment variables are not set.
 *
 * @returns Supabase client instance
 * @throws Error if required environment variables are missing
 */
export function getSupabaseClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseServiceKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error(
      'Supabase configuration is missing. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY environment variables.',
    );
  }

  return createClient(supabaseUrl, supabaseServiceKey);
}
