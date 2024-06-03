# helper functions to assist with ncbi fetch

def read_date_checked(p = "resources/ncbi_date_last_checked.txt"):

    with open(p, 'r') as f:
        date_str = f.readlines()[0]
    return(date_str)

def write_date_checked(p = "resources/ncbi_date_last_checked.txt"):
    from datetime import datetime
    
    TODAY = datetime.today().strftime('%Y-%m-%d')
    with open(p, 'w') as f:
        f.write(TODAY)

def check_ncbi_uploaded(p = "resources/ncbi_date_last_checked.txt"):
    
    import subprocess

    date_checked = read_date_checked()
    cmd = [
        "datasets", "summary", "virus", "genome",
        "taxon", config['ncbi_taxon_id'], 
        "--released-after", f"'{date_checked}'", "|", 
        "grep", "-o", "'\"total_count\":", "\d*'", "|",
        "grep", "-o", "'[0-9]*'",
        ]

    output = subprocess.getoutput(" ".join(cmd))
    
    global FETCH
    if output == '0':
        print(f"No new sequences for: {config['ncbi_taxon_id']}")
        return False
    else:
        print(f"{output} new sequences for: {config['ncbi_taxon_id']}")
        return True

    