from pymouse import PyMouse
import time
import random


if __name__ == '__main__':
    m = PyMouse()
    for i in range(50):
        # sleep 
        time.sleep(0.1)
        x = random.randint(500, 1000)
        y = random.randint(500, 1000)
        m.click(x, y)
