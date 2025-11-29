import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

// Initialize the Supabase client. The credentials are only accessed on the server.
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// This function handles POST requests to /api/submit
export async function POST(request) {
  try {
    // Get the benchmark data from the request body
    const benchmarkData = await request.json();

    // Basic validation on the data itself
    if (!benchmarkData || !benchmarkData.metadata || !benchmarkData.stats) {
      return NextResponse.json(
        { message: 'Invalid benchmark data format.' },
        { status: 400 }
      );
    }

    // Insert the data into the 'benchmarks' table in Supabase
    const { data, error } = await supabase
      .from('benchmarks')
      .insert([
        {
          // Map your JSON object to your table columns
          metadata: benchmarkData.metadata,
          stats: benchmarkData.stats,
        }
      ])
      .select(); // .select() returns the inserted data

    if (error) {
      console.error('Supabase error:', error);
      return NextResponse.json(
        { message: 'Error saving benchmark data', details: error.message },
        { status: 500 }
      );
    }

    // Send a success response
    return NextResponse.json(
      { message: 'Benchmark data submitted successfully.', data: data },
      { status: 201 } // 201 Created is the correct status code for a successful POST
    );

  } catch (err) {
    // Handle cases where the request body is not valid JSON
    if (err instanceof SyntaxError) {
      return NextResponse.json({ message: 'Invalid JSON body.' }, { status: 400 });
    }
    console.error('An unexpected error occurred:', err);
    return NextResponse.json({ message: 'An internal server error occurred.' }, { status: 500 });
  }
}
