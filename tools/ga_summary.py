"""Summarise Firebase Analytics (GA4) for Panduan Umrah: realtime (last 30 min) + last 7 days.

Needs `pip install google-analytics-data` and the gitignored service-account key
docs/panduan-umrah-faeq-*.json (analytics-reader, Viewer on GA4 property 526922638).
Usage: python tools/ga_summary.py [--days N]
"""
import argparse
import glob
import os

from google.analytics.data_v1beta import BetaAnalyticsDataClient
from google.analytics.data_v1beta.types import (
    DateRange, Dimension, Metric, OrderBy, RunReportRequest, RunRealtimeReportRequest)

PROPERTY = 'properties/526922638'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def rows(resp):
    for r in resp.rows:
        yield [d.value for d in r.dimension_values], [m.value for m in r.metric_values]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--days', type=int, default=7)
    days = ap.parse_args().days

    keys = glob.glob(os.path.join(ROOT, 'docs', 'panduan-umrah-faeq-*.json'))
    if not keys:
        raise SystemExit('service-account key not found in docs/ (restore from OneDrive umrah-app-signing)')
    client = BetaAnalyticsDataClient.from_service_account_file(keys[0])

    print('== Realtime (last 30 min) ==')
    total = client.run_realtime_report(RunRealtimeReportRequest(
        property=PROPERTY, metrics=[Metric(name='activeUsers')]))
    print('active users:', next(iter(rows(total)), ([], ['0']))[1][0])
    for name, resp in (
        ('by country', RunRealtimeReportRequest(
            property=PROPERTY, dimensions=[Dimension(name='country')],
            metrics=[Metric(name='activeUsers')])),
        ('events', RunRealtimeReportRequest(
            property=PROPERTY, dimensions=[Dimension(name='eventName')],
            metrics=[Metric(name='eventCount')])),
    ):
        print(f'-- {name}')
        for dims, mets in rows(client.run_realtime_report(resp)):
            print(f'   {dims[0]:<28} {mets[0]}')

    rng = [DateRange(start_date=f'{days}daysAgo', end_date='today')]
    print(f'\n== Last {days} days ==')
    t = client.run_report(RunReportRequest(
        property=PROPERTY, date_ranges=rng,
        metrics=[Metric(name='activeUsers'), Metric(name='newUsers'), Metric(name='sessions')]))
    for _, m in rows(t):
        print(f'active users {m[0]}, new users {m[1]}, sessions {m[2]}')
    print('-- events')
    for dims, mets in rows(client.run_report(RunReportRequest(
            property=PROPERTY, date_ranges=rng, dimensions=[Dimension(name='eventName')],
            metrics=[Metric(name='eventCount'), Metric(name='activeUsers')],
            order_bys=[OrderBy(metric=OrderBy.MetricOrderBy(metric_name='eventCount'), desc=True)]))):
        print(f'   {dims[0]:<28} {mets[0]:>6} events, {mets[1]:>4} users')
    print('-- by day')
    for dims, mets in sorted(rows(client.run_report(RunReportRequest(
            property=PROPERTY, date_ranges=rng, dimensions=[Dimension(name='date')],
            metrics=[Metric(name='activeUsers'), Metric(name='newUsers')])))):
        print(f'   {dims[0]}  active {mets[0]:>4}  new {mets[1]:>4}')
    print('-- by country')
    for dims, mets in rows(client.run_report(RunReportRequest(
            property=PROPERTY, date_ranges=rng, dimensions=[Dimension(name='country')],
            metrics=[Metric(name='activeUsers')],
            order_bys=[OrderBy(metric=OrderBy.MetricOrderBy(metric_name='activeUsers'), desc=True)]))):
        print(f'   {dims[0]:<28} {mets[0]}')


if __name__ == '__main__':
    main()
