from flask import Flask, request
app = Flask(__name__)

@app.route("/getTile")
def get_tile():
    start_time = request.args.get('startTime')
    end_time = request.args.get('endTime')
    start_depth = request.args.get('startDepth')
    end_depth = request.args.get('endDepth')


if __name__ == "__main__":
    app.run()
