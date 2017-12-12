import os

import matplotlib.pyplot as plt


def generate_tiles(x, y, z, output_folder, data_points_per_tile=1000):
    fig = plt.figure()
    fig.set_size_inches(9, 9)
    ax = plt.Axes(fig, [0, 0, 1., 1.])
    ax.set_axis_off()
    fig.add_axes(ax)

    x_range = (x.min(), x.max())
    y_range = (y.min(), y.max())
    ax.set_xlim(x_range)
    ax.set_ylim(y_range)
    ax.scatter(x, y, c=z, s=3)
    # fig.savefig(os.path.join(output_folder, 'test.png'), dpi=80)
    generate_and_split(ax, fig, output_folder, 0, 0, 0, data_points_per_tile, 4)


def generate_and_split(ax, fig, output_folder, zoom_level, column, row, data_points_per_tile, zoom_levels):
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

        # print x_range
        # print y_range

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

        # print y_ranges
        # raise Exception('yo')

        for x, xr in enumerate(x_ranges):
            for y, yr in enumerate(y_ranges):
                if x < (len(x_ranges) - 1) and y < (len(y_ranges) - 1):
                    ax.set_xlim([xr, x_ranges[x + 1]])
                    ax.set_ylim([y_ranges[y + 1], yr])
                    generate_and_split(
                        ax,
                        fig,
                        output_folder,
                        zoom_level,
                        base_column + x,
                        base_row + y,
                        data_points_per_tile,
                        zoom_levels
                    )


def _render_tile(x_data, y_data, output_path):
    # fig.savefig(output_path, dpi=80)
    return
