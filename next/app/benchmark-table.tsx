'use client';

import { useState, useMemo } from 'react';

// This is the same type definition from your page.tsx
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

// Define the props for our component
interface BenchmarkTableProps {
  data: ProcessedBenchmark[];
}

// Define the keys we can sort by
type SortKey =
  | 'createdAt'
  | 'username'
  | 'os'
  | 'cpu'
  | 'memory'
  | 'dockerVersion'
  | 'environment'
  | 'drupalVersion'
  | 'webServer'
  | 'databaseType'
  | 'phpVersion'
  | 'computerModel'
  | 'comment'
  | 'benchmarkVersion'
  | 'numRequests'
  | 'requestsPerSecond'
  | 'avgResponseTime'
  | 'minResponseTime'
  | 'maxResponseTime';

export default function BenchmarkTable({ data }: BenchmarkTableProps) {
  const [sortConfig, setSortConfig] = useState<{
    key: SortKey;
    direction: 'asc' | 'desc';
  } | null>({ key: 'numRequests', direction: 'desc' });

  // useMemo will re-sort the data only when the data prop or the sortConfig changes
  const sortedData = useMemo(() => {
    const sortableData = [...data];
    if (sortConfig !== null) {
      sortableData.sort((a, b) => {
        const aValue = a[sortConfig.key];
        const bValue = b[sortConfig.key];

        if (aValue < bValue) {
          return sortConfig.direction === 'asc' ? -1 : 1;
        }
        if (aValue > bValue) {
          return sortConfig.direction === 'asc' ? 1 : -1;
        }
        return 0;
      });
    }
    return sortableData;
  }, [data, sortConfig]);

  const requestSort = (key: SortKey) => {
    const direction: 'asc' | 'desc' =
      sortConfig && sortConfig.key === key && sortConfig.direction === 'asc'
        ? 'desc'
        : 'asc';
    setSortConfig({ key, direction });
  };

  // Helper function to render the sort arrow
  const getSortArrow = (key: SortKey) => {
    if (!sortConfig || sortConfig.key !== key) return null;
    return sortConfig.direction === 'asc' ? ' ▲' : ' ▼';
  };

  // An array to define our table headers for easier mapping
  const headers: { key: SortKey; label: string; isNumeric?: boolean }[] = [
    { key: 'createdAt', label: 'Date' },
    { key: 'computerModel', label: 'Computer Model' },
    { key: 'os', label: 'OS' },
    { key: 'cpu', label: 'CPU' },
    { key: 'memory', label: 'Memory' },
    { key: 'dockerVersion', label: 'Docker' },
    { key: 'environment', label: 'Env' },
    { key: 'drupalVersion', label: 'Drupal' },
    { key: 'webServer', label: 'Web Server' },
    { key: 'databaseType', label: 'Database' },
    { key: 'phpVersion', label: 'PHP' },
    { key: 'numRequests', label: 'Total Requests', isNumeric: true },
    { key: 'requestsPerSecond', label: 'Req/s', isNumeric: true },
    { key: 'avgResponseTime', label: 'Avg (ms)', isNumeric: true },
    { key: 'minResponseTime', label: 'Min (ms)', isNumeric: true },
    { key: 'maxResponseTime', label: 'Max (ms)', isNumeric: true },
    { key: 'comment', label: 'Comment' },
    { key: 'username', label: 'User' },
    { key: 'benchmarkVersion', label: 'Benchmark version' },
  ];

  return (
    <div className="overflow-x-auto bg-white dark:bg-gray-800 rounded-lg shadow">
      <table className="min-w-full text-sm text-left">
        <thead className="bg-gray-100 dark:bg-gray-700">
          <tr>
            {headers.map((header) => (
              <th
                key={header.key}
                className={`px-3 py-2 font-medium cursor-pointer ${header.isNumeric ? 'text-right' : ''}`}
                onClick={() => requestSort(header.key)}
                style={
                  header.key === 'databaseType' ? { width: '160px' } : undefined
                }
              >
                {header.label}
                {getSortArrow(header.key)}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
          {sortedData.map((item) => {
            const date = new Date(item.createdAt);
            const day = date.getDate();
            const month = (date.getMonth() + 1).toString().padStart(2, '0');
            const year = date.getFullYear();
            const hours = date.getHours().toString().padStart(2, '0');
            const minutes = date.getMinutes().toString().padStart(2, '0');
            const seconds = date.getSeconds().toString().padStart(2, '0');
            const formattedDate = `${day}.${month}.${year} ${hours}:${minutes}:${seconds}`;

            return (
              <tr
                key={item.id}
                className="hover:bg-gray-50 dark:hover:bg-gray-700/50"
              >
                <td className="px-3 py-2 whitespace-nowrap">{formattedDate}</td>
                <td className="px-3 py-2 font-medium">{item.computerModel}</td>
                <td className="px-3 py-2">{item.os}</td>
                <td className="px-3 py-2 truncate max-w-xs">{item.cpu}</td>
                <td className="px-3 py-2">{item.memory}</td>
                <td className="px-3 py-2 font-mono text-xs">
                  {item.dockerVersion}
                </td>
                <td className="px-3 py-2 font-mono">{item.environment}</td>
                <td className="px-3 py-2 font-mono">{item.drupalVersion}</td>
                <td className="px-3 py-2 font-mono">{item.webServer}</td>
                <td className="px-3 py-2 font-mono" style={{ width: '160px' }}>
                  {item.databaseType} {item.databaseVersion}
                </td>
                <td className="px-3 py-2 font-mono">{item.phpVersion}</td>
                <td className="px-3 py-2 font-mono text-right">
                  {item.numRequests}
                </td>
                <td className="px-3 py-2 font-mono text-right">
                  {item.requestsPerSecond}
                </td>
                <td className="px-3 py-2 font-mono text-right">
                  {item.avgResponseTime}
                </td>
                <td className="px-3 py-2 font-mono text-right">
                  {item.minResponseTime}
                </td>
                <td className="px-3 py-2 font-mono text-right">
                  {item.maxResponseTime}
                </td>
                <td className="px-3 py-2">{item.comment}</td>
                <td className="px-3 py-2 font-medium">{item.username}</td>
                <td className="px-3 py-2 font-mono">{item.benchmarkVersion}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
