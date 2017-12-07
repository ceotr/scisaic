import os
import math

import numpy as np
import matplotlib.pyplot as plt


def generate_tiles(x_data, y_data, output_folder, data_points_per_tile=1000):
    generate_and_split(x_data, y_data, output_folder, 0, 0, 0, data_points_per_tile)


def generate_and_split(x_data, y_data, output_folder, zoom_level, column, row, data_points_per_tile):
    print len(x_data), len(y_data)
    output_dir = os.path.join(output_folder, str(zoom_level), str(column))
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    output_file = os.path.join(output_dir, "%s.png" % row)

    _render_tile(x_data, y_data, output_file)

    if len(x_data) > data_points_per_tile:
        middle_index = int(math.floor(len(x_data) / 2))
        x_split = np.split(x_data, [middle_index])
        y_split = np.split(y_data, [middle_index])

        for x in x_split:
            for y in y_split:
                if len(x) != len(y):
                    print x_split
                    print y_split
                    raise Exception("Something weird happened in the split")

        zoom_level = zoom_level + 1
        base_column = column * 2
        base_row = row * 2

        for col, x in enumerate(x_split):
            for row, y in enumerate(y_split):
                generate_and_split(x, y, output_folder, zoom_level, base_column + col, base_row + row, data_points_per_tile)


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
