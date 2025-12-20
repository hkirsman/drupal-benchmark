import { createClient } from '@supabase/supabase-js';

/**
 * Custom error class for Supabase configuration issues.
 */
export class SupabaseConfigurationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'SupabaseConfigurationError';
    // Maintains proper stack trace for where our error was thrown (only available on V8)
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, SupabaseConfigurationError);
    }
  }
}

/**
 * Get Supabase client with lazy initialization.
 * This prevents build-time errors when environment variables are not set.
 *
 * @returns Supabase client instance
 * @throws SupabaseConfigurationError if required environment variables are missing
 */
export function getSupabaseClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseServiceKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!supabaseUrl || !supabaseServiceKey) {
    throw new SupabaseConfigurationError(
      'Supabase configuration is missing. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY environment variables.',
    );
  }

  return createClient(supabaseUrl, supabaseServiceKey);
}
