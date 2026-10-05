import random
import sys
import pathlib

def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 32
    random.seed(42)
    script_dir = pathlib.Path(__file__).resolve().parent
    out_dir = script_dir / "FIFO_gp" / "FIFO_gp.sim" / "sim_1" / "behav" / "xsim"
    out_path = out_dir / "input.txt"
    with open(out_path, "w") as f:
        for _ in range(n):
            a = random.randint(0, 0xFF)
            b = random.randint(0, 0xFF)
            f.write(f"{a:02x} {b:02x}\n")
    print(f"Wrote {n} pairs to {out_path}")

if __name__ == "__main__":
    main()