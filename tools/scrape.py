#!/usr/bin/env python3
"""
Firecrawl pre-enrichment scraper.
Fetches real web data before Claude analysis so the model only reasons, never fetches.

Usage:
  scrape.py page   <url>                  Scrape one page → clean markdown
  scrape.py crawl  <url> [--limit N]      Crawl domain → article list + content
  scrape.py search <query> [--limit N]    Web search → top results with snippets
"""
import sys
import os
import argparse

CONTENT_CAP = 3000  # chars per page — keeps token usage predictable


def client():
    from firecrawl import FirecrawlApp
    key = os.environ.get("FIRECRAWL_API_KEY", "")
    if not key:
        print("ERROR: FIRECRAWL_API_KEY not set", file=sys.stderr)
        sys.exit(1)
    return FirecrawlApp(api_key=key)


def cmd_page(url: str) -> None:
    result = client().scrape_url(url, formats=["markdown"])
    meta = result.get("metadata", {})
    title = meta.get("title", url)
    md = (result.get("markdown", "") or "")[:CONTENT_CAP]
    print(f"# {title}\nURL: {url}\n\n{md}")


def cmd_crawl(url: str, limit: int) -> None:
    if not url.startswith("http"):
        url = f"https://{url}"
    result = client().crawl_url(url, limit=limit, scrape_options={"formats": ["markdown"]})
    pages = result.get("data", [])
    if not pages:
        print(f"No pages found at {url}")
        return
    for p in pages:
        meta = p.get("metadata", {})
        title = meta.get("title", "Untitled")
        src = meta.get("sourceURL", "")
        desc = meta.get("description", "")
        md = (p.get("markdown", "") or "")[:CONTENT_CAP]
        print(f"## {title}\nURL: {src}\nDescription: {desc}\n\n{md}\n\n---")


def cmd_search(query: str, limit: int) -> None:
    result = client().search(query, limit=limit)
    items = result.get("data", [])
    if not items:
        print(f"No results for: {query}")
        return
    for i, item in enumerate(items, 1):
        title = item.get("title", "")
        url = item.get("url", "")
        snippet = item.get("description", "")
        print(f"{i}. {title}\n   {url}\n   {snippet}\n")


def main():
    parser = argparse.ArgumentParser(description="Firecrawl pre-enrichment scraper")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("page", help="Scrape a single page")
    p.add_argument("url")

    p = sub.add_parser("crawl", help="Crawl a domain for article content")
    p.add_argument("url")
    p.add_argument("--limit", type=int, default=8)

    p = sub.add_parser("search", help="Web search — return top results")
    p.add_argument("query", nargs="+")
    p.add_argument("--limit", type=int, default=8)

    args = parser.parse_args()

    if args.cmd == "page":
        cmd_page(args.url)
    elif args.cmd == "crawl":
        cmd_crawl(args.url, args.limit)
    elif args.cmd == "search":
        cmd_search(" ".join(args.query), args.limit)


if __name__ == "__main__":
    main()
