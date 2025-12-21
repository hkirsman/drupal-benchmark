import Image from 'next/image';
import { getSupabaseClient, SupabaseConfigurationError } from '@/lib/supabase';
import BenchmarkTable from './benchmark-table';

// -----------------------------------------------------------------------------
// V-- THIS IS THE NEW LINE YOU NEED TO ADD --V
// This tells Next.js to treat this page as a Static Site Generation (SSG) page
// that revalidates at most once every 300 seconds (5 minutes).
export const revalidate = 300;
// -----------------------------------------------------------------------------

// Type definitions for Supabase benchmark records
interface BenchmarkStat {
  name: string;
  num_requests: number;
  total_response_time: number;
  min_response_time: number;
  max_response_time: number;
}

interface BenchmarkMetadata {
  user_name?: string;
  environment: string;
  drupal_version: string;
  docker_version?: string;
  web_server?: string;
  database?: {
    type?: string;
    version?: string;
  };
  php_version?: string;
  computer_model?: string;
  comment?: string;
  benchmark_version?: string;
  system: {
    os: string;
    cpu: string;
    memory: string;
  };
}

interface BenchmarkRecord {
  id: string;
  created_at: string;
  metadata: BenchmarkMetadata;
  stats: BenchmarkStat[];
}

// The type definition remains the same
interface ProcessedBenchmark {
  id: string;
  createdAt: string;
  username: string;
  os: string;
  cpu: string;
  memory: string;
  dockerVersion: string;
  environment: string;
  drupalVersion: string;
  webServer: string;
  databaseType: string;
  databaseVersion: string;
  phpVersion: string;
  computerModel: string;
  comment: string;
  benchmarkVersion: string;
  numRequests: number;
  requestsPerSecond: number;
  avgResponseTime: number;
  minResponseTime: number;
  maxResponseTime: number;
}

export default async function Home() {
  // Initialize Supabase client (lazy initialization to avoid build-time errors)
  let benchmarks: BenchmarkRecord[] = [];
  let error: Error | null = null;

  try {
    const supabase = getSupabaseClient();

    // REMOVE THE .context() CALL FROM THIS QUERY
    const result = await supabase
      .from('benchmarks')
      .select('*')
      .order('created_at', { ascending: false });

    // Handle Supabase query errors (result.error is a PostgrestError, not a standard Error)
    if (result.error) {
      error = new Error(
        `Supabase query error: ${result.error.message || 'Unknown error'}`,
        { cause: result.error },
      );
    } else {
      benchmarks = result.data || [];
    }
  } catch (err) {
    // Handle missing environment variables during build / runtime configuration issues
    if (err instanceof SupabaseConfigurationError) {
      console.error(
        'Supabase configuration missing. Benchmarks cannot be loaded until Supabase environment variables are set.',
      );
      error = new Error(
        'Supabase configuration is missing. Please configure Supabase environment variables.',
        { cause: err },
      );
    } else if (err instanceof Error) {
      // Store the original error directly to preserve stack trace and type information
      console.error('Error initializing Supabase:', err);
      error = err;
    } else {
      // Handle non-Error exceptions (shouldn't happen, but TypeScript requires it)
      console.error('Unexpected error type:', err);
      error = new Error('An unexpected error occurred', { cause: err });
    }
  }

  if (error) {
    console.error('Error fetching benchmarks:', error);
    return (
      <main className="p-20">
        <p className="text-red-500">
          Error fetching data. Check server console.
        </p>
      </main>
    );
  }

  // The rest of your data processing logic remains exactly the same...
  const processedData: ProcessedBenchmark[] = benchmarks.flatMap((record) => {
    const adminStats = record.stats.find(
      (stat: { name: string }) => stat.name === '/admin/modules',
    );
    if (!adminStats) return [];

    const numRequests = adminStats.num_requests;
    const avgResponseTime = Math.round(
      adminStats.total_response_time / numRequests,
    );
    const requestsPerSecond = (numRequests / 30).toFixed(2);

    return [
      {
        id: record.id,
        createdAt: record.created_at,
        username: record.metadata.user_name || 'anonymous',
        os: record.metadata.system.os,
        cpu: record.metadata.system.cpu,
        memory: record.metadata.system.memory,
        dockerVersion: record.metadata.docker_version || '-',
        environment: record.metadata.environment,
        drupalVersion: record.metadata.drupal_version,
        webServer: record.metadata.web_server || 'Unknown',
        databaseType: record.metadata.database?.type || 'Unknown',
        databaseVersion: record.metadata.database?.version || 'Unknown',
        phpVersion: record.metadata.php_version || 'Unknown',
        computerModel: record.metadata.computer_model || 'Unknown',
        comment: record.metadata.comment || '',
        benchmarkVersion: record.metadata.benchmark_version || 'Unknown',
        numRequests,
        requestsPerSecond: parseFloat(requestsPerSecond),
        avgResponseTime,
        minResponseTime: Math.round(adminStats.min_response_time),
        maxResponseTime: Math.round(adminStats.max_response_time),
      },
    ];
  });

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100 p-4 sm:p-8">
      <main className="max-w-[1450px] xl:max-w-[1680px] 2xl:max-w-[1920px] mx-auto">
        <div className="mb-8">
          <h1 className="text-2xl font-bold tracking-tight">
            Drupal Benchmark Results
          </h1>
        </div>

        <BenchmarkTable data={processedData} />

        <footer className="text-center mt-8 text-sm text-gray-500">
          <div className="flex items-center justify-center gap-2 mb-2">
            <a
              href="https://nextjs.org"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Image
                className="dark:invert"
                src="/next.svg"
                alt="Next.js logo"
                width={40}
                height={10}
                priority
              />
            </a>
          </div>
          <p>
            Displaying {processedData.length} benchmark results. Click headers
            to sort.
          </p>
        </footer>
      </main>
    </div>
  );
}
