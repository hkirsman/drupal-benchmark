import { NextResponse } from 'next/server';
import { revalidatePath } from 'next/cache';

export async function POST(request) {
  try {
    // Get the authorization header
    const authHeader = request.headers.get('authorization');
    const expectedSecret = process.env.SUBMISSION_SECRET;

    // Check if the request is authorized
    if (!authHeader || !expectedSecret || authHeader !== `Bearer ${expectedSecret}`) {
      return NextResponse.json(
        { message: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Revalidate the home page and all pages
    revalidatePath('/', 'page');
    revalidatePath('/api/submit', 'page');

    // Also revalidate the entire app
    revalidatePath('/', 'layout');

    return NextResponse.json(
      {
        message: 'Cache cleared successfully',
        timestamp: new Date().toISOString()
      },
      { status: 200 }
    );

  } catch (error) {
    console.error('Error clearing cache:', error);
    return NextResponse.json(
      {
        message: 'Error clearing cache',
        error: error.message
      },
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
