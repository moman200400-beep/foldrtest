import subprocess
import time

def run_flutter_and_capture():
    print("Starting flutter build/run...")
    process = subprocess.Popen(
        ['flutter.bat', 'run', '-d', 'chrome'],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding='utf-8',
        errors='replace'
    )
    
    with open("crash_trace.txt", "w", encoding="utf-8") as f:
        start_time = time.time()
        # Read for 100 seconds
        while time.time() - start_time < 100:
            if process.poll() is not None:
                break
            line = process.stdout.readline()
            if line:
                # write and flush to see it immediately
                f.write(line.replace('\r', '\n'))
                f.flush()
    
    print("Done gathering logs. Terminating app...")
    process.terminate()

if __name__ == '__main__':
    run_flutter_and_capture()
