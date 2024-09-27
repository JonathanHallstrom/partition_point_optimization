import matplotlib.pyplot as plt
import matplotlib.ticker as tkr  
import pandas as pd

def main(n, is_last):
    file = open(f"data{n}.txt", "r")
    lines = file.readlines()

    data = []

    for i in range(0, len(lines), 1):
        line = lines[i]
        line = line.split(",")

        size = int(line[0])

        new_time = float(line[1])
        old_time = float(line[2])

        data.append([size, new_time, old_time])

    file.close()

    df = pd.DataFrame(data, columns=["size", "new", "old"])

    df_to_plot = df

    plt.plot(df_to_plot["size"], df_to_plot["new"].rolling(20).quantile(0.1), label="new")
    plt.plot(df_to_plot["size"], df_to_plot["old"].rolling(20).quantile(0.1), label="old")
    

    plt.xlabel("size(bytes)")
    plt.ylabel("runtime(ns)")
    
    plt.xscale('log')
    plt.yscale('log')

    simple_formatter = lambda x, _: "%0.1f" % x
    
    
    plt.gca().yaxis.set_major_formatter(tkr.FuncFormatter(simple_formatter))
    plt.gca().yaxis.set_minor_formatter(tkr.FuncFormatter(simple_formatter))
    plt.gca().grid(True, which="both", axis="y", linestyle="--", linewidth=1)
    plt.gca().grid(True, which="major", axis="x", linestyle="--", linewidth=1)
    
    plt.gca().yaxis.set_major_locator(tkr.LogLocator(base=10.0, subs=[], numticks=1))
    plt.gca().yaxis.set_minor_locator(tkr.LogLocator(base=10.0, subs=range(10), numticks=1))
    plt.legend()

    # plt.title(f"partition point benchmark (queries on {f'range [0, {2 ** n} )' if not is_last else 'whole range'})")
    plt.title(f"partition point benchmark ({n}% of queries unpredictable)")

    plt.savefig(f"graph{n}.png")
    plt.clf()
    file.close()

if __name__ == "__main__": 
    num_benches = 101 
    for n in range(num_benches):
        main(n, n == num_benches - 1)
