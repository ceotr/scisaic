import os
import json

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import colors


def generate_tiles_old(x, y, z, output_folder):
    ax, fig = setup_plot()

    x_range = (x.min(), x.max())
    y_range = (y.min(), y.max())
    ax.set_xlim(x_range)
    ax.set_ylim(y_range)
    ax.scatter(x, y, c=z, s=3)
    # fig.savefig(os.path.join(output_folder, 'test.png'), dpi=80)
    generate_and_split(ax, fig, output_folder, 4, 0, 0, 0)


def generate_json(ax, fig, filepath):
    p = None

    if len(ax.collections) > 0:
        p = ax.collections[-1]
    elif len(ax.lines) > 0:
        p = ax.lines[-1]

    if p is None:
        raise Exception("No plots added yet, cannot generate JSON")

    output = {
        'title': ax.title.get_text(),
        'xlabel': ax.get_xlabel(),
        'ylabel': ax.get_ylabel(),
        'colorbar': [],
        'x_range': ax.get_xlim(),
        'y_range': ax.get_ylim(),
        'clim': p.get_clim()
    }
    for i in np.linspace(0, 1, 10):
        rgba = p.to_rgba(i, norm=False)
        output['colorbar'].append(colors.to_hex(rgba))

    with open(filepath, 'w') as f:
        json.dump(output, f)
    return output


def setup_plot():
    fig = plt.figure()
    fig.set_size_inches(9, 9)
    ax = plt.Axes(fig, [0, 0, 1., 1.])
    ax.set_axis_off()
    fig.add_axes(ax)
    return ax, fig


def generate_and_split(ax, fig, output_folder, zoom_levels=4, zoom_level=0, column=0, row=0):
    output_dir = os.path.join(output_folder, str(zoom_level), str(column))
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    output_file = os.path.join(output_dir, "%s.png" % row)
    print "Saving %s" % output_file
    fig.savefig(output_file, dpi=80)

    if zoom_level < zoom_levels:
        zoom_level = zoom_level + 1
        base_column = column * 2
        base_row = row * 2

        x_range = ax.get_xlim()
        y_range = ax.get_ylim()

        x_ranges = [
            x_range[0],
            (x_range[0] + ((x_range[1] - x_range[0]) / 2)),
            x_range[1]
        ]
        y_ranges = [
            y_range[1],
            (y_range[0] + ((y_range[1] - y_range[0]) / 2)),
            y_range[0]
        ]

        for x, xr in enumerate(x_ranges):
            for y, yr in enumerate(y_ranges):
                if x < (len(x_ranges) - 1) and y < (len(y_ranges) - 1):
                    ax.set_xlim([xr, x_ranges[x + 1]])
                    ax.set_ylim([y_ranges[y + 1], yr])
                    generate_and_split(
                        ax,
                        fig,
                        output_folder,
                        zoom_levels,
                        zoom_level,
                        base_column + x,
                        base_row + y,
                    )


def _render_tile(x_data, y_data, output_path):
    # fig.savefig(output_path, dpi=80)
    return
