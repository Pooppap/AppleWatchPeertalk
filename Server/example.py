import random 
import time
import matplotlib.pyplot as plt
import matplotlib.animation as animation

fig = plt.figure()
ax1 = fig.add_subplot(1,1,1)
xs = []
ys = []
line, = ax1.plot(xs, ys)
plt.xlabel('Value')
plt.ylabel('Time')
plt.title('Live Graph')

def animate(frame, xs, ys):
    xs.append(frame)
    ys.append(round(random.uniform(-120,20),2))
    x = xs[-20:]
    y = ys[-20:]
    line.set_xdata(x)
    line.set_ydata(y)
    ax1.set_xlim(min(x)-1, max(x)+1)
    ax1.set_ylim(min(y)-1, max(y)+1)
    ax1.set_xticks(list(range(min(x), max(x)+1)))
    return line

ani = animation.FuncAnimation(fig, animate, fargs = (xs,ys), interval=100) 
plt.show()