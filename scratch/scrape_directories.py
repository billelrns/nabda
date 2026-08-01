import requests
from bs4 import BeautifulSoup
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

def test_dabadoc():
    print("--- Testing Dabadoc ---")
    urls = [
        "https://www.dabadoc.com/dz/doctors/gynecologue-obstetricien/alger",
        "https://www.dabadoc.com/dz/doctors/pediatre/alger",
    ]
    doctors = []
    for url in urls:
        try:
            r = requests.get(url, headers=headers, timeout=15)
            print(f"URL: {url} Status: {r.status_code}")
            soup = BeautifulSoup(r.text, 'html.parser')
            # Look for doctor items
            cards = soup.find_all(['div', 'article'], class_=re.compile(r'doctor|card|profile', re.I))
            print(f"Found {len(cards)} card elements")
            
            # Extract links or text
            links = soup.find_all('a', href=re.compile(r'/dz/doc/'))
            print(f"Found {len(links)} doctor links")
            for a in links[:5]:
                print(" Doctor Link:", a.get('href'), "| Text:", a.get_text(strip=True))
        except Exception as e:
            print(f"Error {url}: {e}")

def test_algerie_docto():
    print("\n--- Testing Algerie-Docto ---")
    url = "https://algerie-docto.com/"
    try:
        r = requests.get(url, headers=headers, timeout=15)
        print(f"URL: {url} Status: {r.status_code}")
        soup = BeautifulSoup(r.text, 'html.parser')
        links = soup.find_all('a', href=True)
        print(f"Found {len(links)} total links on Algerie-Docto")
        spec_links = [a['href'] for a in links if 'gyneco' in a['href'].lower() or 'pediat' in a['href'].lower() or 'specialite' in a['href'].lower()]
        print("Specialty links found:", spec_links[:10])
    except Exception as e:
        print(f"Error {url}: {e}")

if __name__ == "__main__":
    test_dabadoc()
    test_algerie_docto()
