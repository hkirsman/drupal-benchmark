import { createClient } from '@supabase/supabase-js';
import Image from 'next/image';
import BenchmarkTable from './benchmark-table';

// -----------------------------------------------------------------------------
// V-- THIS IS THE NEW LINE YOU NEED TO ADD --V
// This tells Next.js to treat this page as a Static Site Generation (SSG) page
// that revalidates at most once every 300 seconds (5 minutes).
export const revalidate = 300;
// -----------------------------------------------------------------------------

// The type definition remains the same
interface ProcessedBenchmark {
  id: number;
  createdAt: string;
  username: string;
  os: string;
  cpu: string;
  memory: string;
  dockerVersion: string;
  environment: string;
  drupalVersion: string;
  numRequests: number;
  avgResponseTime: number;
  minResponseTime: number;
  maxResponseTime: number;
  requestsPerSecond: string;
}

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
);

export default async function Home() {
  // REMOVE THE .context() CALL FROM THIS QUERY
  const { data: benchmarks, error } = await supabase
    .from('benchmarks')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching benchmarks:', error);
    return <main className="p-20"><p className="text-red-500">Error fetching data. Check server console.</p></main>;
  }

  // The rest of your data processing logic remains exactly the same...
  const processedData: ProcessedBenchmark[] = benchmarks.flatMap(record => {
    const adminStats = record.stats.find((stat: any) => stat.name === '/admin/modules');
    if (!adminStats) return [];

    const numRequests = adminStats.num_requests;
    const avgResponseTime = Math.round(adminStats.total_response_time / numRequests);
    const requestsPerSecond = (numRequests / 30).toFixed(2);

    return [{
      id: record.id,
      createdAt: record.created_at,
      username: record.metadata.user_name || 'anonymous',
      os: record.metadata.system.os,
      cpu: record.metadata.system.cpu,
      memory: record.metadata.system.memory,
      dockerVersion: record.metadata.docker_version || '-',
      environment: record.metadata.environment,
      drupalVersion: record.metadata.drupal_version,
      numRequests: numRequests,
      avgResponseTime: avgResponseTime,
      minResponseTime: Math.round(adminStats.min_response_time),
      maxResponseTime: Math.round(adminStats.max_response_time),
      requestsPerSecond: requestsPerSecond,
    }];
  });

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100 p-4 sm:p-8">
      <main className="max-w-7xl mx-auto">
        <div className="flex items-center gap-4 mb-8">
          <Image
            className="dark:invert"
            src="/next.svg"
            alt="Next.js logo"
            width={150}
            height={32}
            priority
          />
          <h1 className="text-2xl font-bold tracking-tight">Drupal Benchmark Results</h1>
        </div>

        <BenchmarkTable data={processedData} />

         <footer className="text-center mt-8 text-sm text-gray-500">
            <p>Displaying {processedData.length} benchmark results for <code>/admin/modules</code>. Click headers to sort.</p>
        </footer>
      </main>
    </div>
  );
}
