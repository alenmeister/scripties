import keyboard
import time


def press_key():
    key_to_press = 'ctrl+f10'
    keyboard.press_and_release(key_to_press)
    print(f"Key '{key_to_press}' pressed at {time.strftime('%Y-%m-%d %H:%M:%S')}")


def main():
    interval_minutes = 2

    try:
        while True:
            press_key()
            time.sleep(60 * interval_minutes)

    except KeyboardInterrupt:
        print("\nTerminated by user")


if __name__ == "__main__":
    main()
