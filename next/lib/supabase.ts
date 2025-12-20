import { createClient, SupabaseClient } from '@supabase/supabase-js';

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

// Module-level cache for the Supabase client instance
let supabaseClient: SupabaseClient | null = null;

/**
 * Get Supabase client with lazy initialization and caching.
 * This prevents build-time errors when environment variables are not set,
 * and reuses the same client instance across multiple calls for better performance.
 *
 * @returns Supabase client instance
 * @throws SupabaseConfigurationError if required environment variables are missing
 */
export function getSupabaseClient(): SupabaseClient {
  // Return cached client if it exists
  if (supabaseClient) {
    return supabaseClient;
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabasePublishableKey =
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!supabaseUrl || !supabasePublishableKey) {
    throw new SupabaseConfigurationError(
      'Supabase configuration is missing. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY environment variables.',
    );
  }

  // Create and cache the client
  supabaseClient = createClient(supabaseUrl, supabasePublishableKey);
  return supabaseClient;
}
