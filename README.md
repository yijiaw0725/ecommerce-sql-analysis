# E-commerce Customer Analysis with SQL

Customer segmentation on ~100K real e-commerce orders: a Python script loads the raw CSVs into a SQLite database, then SQL (CTEs, window functions, multi-table joins) runs an RFM analysis that groups every customer into one of five actionable segments.

## Why

E-commerce teams can't treat all customers the same — a one-time buyer from a year ago and a loyal repeat customer need different marketing. This project answers: **who are our best customers, who is slipping away, and where is the revenue concentrated?**

## Dataset

[Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — real, anonymized orders placed on the Olist marketplace between September 2016 and October 2018: 99,441 orders from 96,096 customers, of which 96,478 delivered orders are used for the analysis.

| Table | What it contains |
|---|---|
| `customers` | Customer IDs and location |
| `orders` | Order status and timestamps |
| `order_items` | Products, prices, and freight per order |
| `payments` | Payment type and value |
| `products` | Product categories and attributes |

## Key findings

| Segment | Customers | % of Customers | Revenue | % of Revenue | Avg Spend | Avg Days Since Purchase |
|---|---:|---:|---:|---:|---:|---:|
| **At Risk** | 21,897 | 23.5% | $5.30M | 34.4% | $242 | 395 |
| **Best** | 15,127 | 16.2% | $4.69M | 30.4% | $310 | 93 |
| **Loyal** | 18,854 | 20.2% | $3.36M | 21.8% | $178 | 168 |
| **Standard** | 30,380 | 32.5% | $1.68M | 10.9% | $55 | 290 |
| **New & Promising** | 7,099 | 7.6% | $0.39M | 2.5% | $55 | 45 |

- **The single biggest opportunity is win-back, not acquisition.** 21,897 At Risk customers — people who used to spend well but have gone quiet for ~13 months on average — account for $5.3M (34%) of historical revenue, the largest share of any segment.
- **Revenue is concentrated at the top.** Best + Loyal customers are 36% of the base but drive 52% of revenue, with Best customers averaging $310 each — nearly 6× a Standard customer.
- **97% of customers purchased exactly once.** Repeat purchase, not traffic, is the structural growth lever — which is also why the segmentation needed care (see methodology note below).

## How the segmentation works

Each customer is scored 1–5 on three dimensions using `NTILE(5)` window functions, based on delivered orders only (reference date: 2018-09-01, near the end of the dataset):

- **Recency** — days since last purchase (more recent = higher score)
- **Frequency** — number of orders
- **Monetary** — total amount spent

The scores then map to segments:

| Segment | Definition |
|---|---|
| **Best** | Top-tier on all three dimensions (R, F, M ≥ 4) |
| **Loyal** | Solid on all three dimensions (R, F, M ≥ 3) |
| **New & Promising** | First purchase within the last 90 days — too early to judge, worth nurturing |
| **At Risk** | Bottom 40% on recency but mid-to-high spend — worth winning back |
| **Standard** | Everyone else |

**Methodology note:** because 97% of customers bought exactly once, ranking frequency alone produces massive ties that `NTILE` would split arbitrarily. The frequency score therefore uses total spend as a tie-breaker, and the At Risk definition filters on monetary score so the segment captures *valuable* lapsed customers — a list a marketing team could actually act on — rather than every lapsed low-spender.

## Project structure

```
├── scripts/
│   └── csv_to_db.py             # Loads the 5 raw CSVs into a SQLite database
├── sql_queries/
│   ├── 01_exploration.sql       # Data exploration: volumes, date ranges, order status
│   ├── 02_rfm_segmentation.sql  # Per-customer RFM scoring and segmentation
│   └── 03_segment_summary.sql   # Rolls segments up to the summary table above
└── *.csv                        # Raw Olist data files
```

## How to run

```bash
# 1. Build the database from the CSVs (creates database/ecommerce.db)
pip install pandas
python3 scripts/csv_to_db.py

# 2. Run the analysis
sqlite3 database/ecommerce.db < sql_queries/01_exploration.sql
sqlite3 database/ecommerce.db < sql_queries/02_rfm_segmentation.sql
sqlite3 database/ecommerce.db < sql_queries/03_segment_summary.sql
```

## Tools

- **SQL (SQLite)** — multi-table joins, CTEs, `NTILE` window functions
- **Python (pandas)** — CSV-to-database ETL
