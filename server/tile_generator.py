import numpy as np
import matplotlib.pyplot as plt


def generate_tiles(x_data, y_data, output_folder, data_points_per_tile=1000):
    tile_width = x_data.diff().mean() * 1000
    tile_height = y_data.diff().mean() * 1000

    x_range = (x_data.min(), x_data.max())
    y_range = (y_data.min(), y_data.max())

    x_tiles = np.arange(x_range[0], x_range[1], tile_width)
    y_tiles = np.arange(y_range[0], y_range[1], tile_height)



def _render_tile(x_data, y_data, output_path):
    fig = plt.figure()
    fig.set_size_inches(1, 1)
    ax = plt.Axes(fig, [0, 0, 1., 1.])
    ax.set_axis_off()
    fig.add_axes(ax)

    x_range = (x_data.min(), x_data.max())
    y_range = (y_data.min(), y_data.max())
    ax.set_xlim(x_range)
    ax.set_ylim(y_range)

    ax.plot(x_data, y_data)
    fig.savefig(output_path, dpi=80)
