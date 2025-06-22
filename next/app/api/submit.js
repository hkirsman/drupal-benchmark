import { createClient } from '@supabase/supabase-js';

// Initialize the Supabase client.
// These credentials are kept secure on the server and are never exposed to the browser.
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
// This is the secret service_role key, which can bypass Row Level Security.
// Keep this in a .env.local file and NEVER expose it publicly.
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

export default async function handler(req, res) {
  // 1. Validate the request
  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Method Not Allowed' });
  }

  // Optional: Add a simple secret to prevent random abuse
  const SUBMISSION_SECRET = process.env.SUBMISSION_SECRET;
  if (req.headers['authorization'] !== `Bearer ${SUBMISSION_SECRET}`) {
    return res.status(401).json({ message: 'Unauthorized' });
  }

  // 2. Get the benchmark data from the request body
  const benchmarkData = req.body;

  // Basic validation on the data itself
  if (!benchmarkData || !benchmarkData.metadata || !benchmarkData.stats) {
      return res.status(400).json({ message: 'Invalid benchmark data format.' });
  }

  // 3. Insert the data into the 'benchmarks' table in Supabase
  const { data, error } = await supabase
    .from('benchmarks') // Your table name
    .insert([
      {
        // Map your JSON object to your table columns
        // Assuming your table has columns 'metadata', 'stats', etc.
        metadata: benchmarkData.metadata,
        stats: benchmarkData.stats,
        // You could add more columns here, e.g., created_at is handled automatically
      }
    ]);

  if (error) {
    console.error('Supabase error:', error);
    return res.status(500).json({ message: 'Error saving benchmark data', details: error.message });
  }

  // 4. Send a success response
  res.status(201).json({ message: 'Benchmark data submitted successfully.', data: data });
}
