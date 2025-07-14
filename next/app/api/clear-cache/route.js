import { NextResponse } from 'next/server';
import { revalidatePath } from 'next/cache';

export async function POST() {
  try {
    // Revalidate the home page to clear the cache
    revalidatePath('/');

    return NextResponse.json(
      { message: 'Cache cleared successfully.' },
      { status: 200 }
    );
  } catch (error) {
    console.error('Error clearing cache:', error);
    return NextResponse.json(
      { message: 'Error clearing cache.' },
      { status: 500 }
    );
  }
}

// Also allow GET requests for easier testing
export async function GET(request) {
  return NextResponse.json(
    {
      message: 'Cache clear endpoint. Use POST with Authorization header.',
      usage: 'curl -X POST -H "Authorization: Bearer YOUR_SECRET" https://your-domain.com/api/clear-cache'
    },
    { status: 200 }
  );
}
