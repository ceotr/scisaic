$(window).on "load", ->
    tms_url = "tiles2/{z}/{x}/{y}.png"
    starting_zoom = 0
    max_zoom = 4
    tile_size = 720

    canvas = $('#plot')
    plotContainer = $('#plotContainer')
    stage = new createjs.Stage(canvas[0])
    parentContainer = new createjs.Container()
    stage.addChild(parentContainer)

    starting_tile = tms_url.replace('{z}', starting_zoom).replace('{x}', '0').replace('{y}', '0')
    container = null

    context = stage.canvas.getContext("2d")
    context.imageSmoothingEnabled = false

    viewportUpdate = new Event('viewportUpdate')


    tileManager = {
        stage: stage,
        canvas: canvas,
        parentContainer: parentContainer,
        currentContainer: container,
        previousContainer: null,
        loadedTiles: null,
        zoomLevel: starting_zoom,
        maxZoom: max_zoom,
        tmsUrl: tms_url,
        tileSize: tile_size,
        layerBounds: {
            width: null,
            height: null
        },

        setLoaded: (column, row) ->
            if tileManager.loadedTiles == null
                tileManager.loadedTiles = []
            if !(column in tileManager.loadedTiles)
                tileManager.loadedTiles[column] = []
            tileManager.loadedTiles[column][row] = true


        isLoaded: (column, row) ->
            if !(tileManager.loadedTiles == null) && column in tileManager.loadedTiles && row in tileManager.loadedTiles[column]
                return true
            else
                return false


        getView: () ->
            canvas = tileManager.canvas
            cSize = {
                width: canvas.width(),
                height: canvas.height()
            }
            contBounds = tileManager.parentContainer.getBounds()
            currContBounds = tileManager.currentContainer.getBounds()
            
            # Adjust the view so it's scaled for zoom
            xScale = tileManager.layerBounds.width / contBounds.width
            yScale = tileManager.layerBounds.height / contBounds.height

            console.log(yScale)

            # viewBounds = {
            #     x1: contBounds.x * xScale * -1,
            #     y1: contBounds.y * yScale * -1,
            #     x2: (contBounds.x * xScale * -1) + cSize.width,
            #     y2: (contBounds.y * yScale * -1) + cSize.height, 
            # }
            viewBounds = {
                x1: (contBounds.x * -1) / contBounds.width * currContBounds.width,
                y1: (contBounds.y * -1) / contBounds.height * currContBounds.height,
                x2: ((contBounds.x * -1) + cSize.width) / contBounds.width * currContBounds.width,
                y2: ((contBounds.y * -1) + cSize.height) / contBounds.height * currContBounds.height,
            }
            return viewBounds


        getDisplayedTiles: () ->
            view = tileManager.getView()

            tileBounds = {
                x1: Math.floor(view.x1 / tileManager.tileSize),
                y1: Math.floor(view.y1 / tileManager.tileSize),
                x2: Math.ceil(view.x2 / tileManager.tileSize) - 1,
                y2: Math.ceil(view.y2 / tileManager.tileSize) - 1,
            }
            return tileBounds


        getNextTiles: () ->
            currentTiles = tileManager.getDisplayedTiles()
            currentTiles.x1 = (currentTiles.x1 * 2) - 1
            currentTiles.y1 = (currentTiles.y1 * 2) - 1
            currentTiles.x2 = (currentTiles.x2 * 2) + 1
            currentTiles.y2 = (currentTiles.y2 * 2) + 1
            return currentTiles


        getPreviousTiles: () ->
            currentTiles = tileManager.getDisplayedTiles()
            currentTiles.x1 = (Math.floor(currentTiles.x1 / 2)) - 1
            currentTiles.y1 = (Math.floor(currentTiles.y1 / 2)) - 1
            currentTiles.x2 = (Math.ceil(currentTiles.x2 / 2)) + 1
            currentTiles.y2 = (Math.ceil(currentTiles.y2 / 2)) + 1
            return currentTiles


        addLayer: (level=tileManager.zoomLevel, loadTiles=null) ->
            tileManager.previousContainer = tileManager.currentContainer
            tileManager.currentContainer = new createjs.Container()
            container = tileManager.currentContainer
            tileManager.layerBounds.width = tileManager.layerBounds.height = tileManager.tileSize * (2**level)
            tileManager.currentContainer.setBounds(0, 0, tileManager.layerBounds.width, tileManager.layerBounds.height)
            tileManager.parentContainer.addChild(tileManager.currentContainer)
            bounds = stage.getBounds()
            tileShape = {
                x: 0,
                y: 0
            }

            if loadTiles == null
                xRange = [0..2**level - 1]
                yRange = [0..2**level - 1]
            else
                xRange = [loadTiles.x1..(loadTiles.x2)]
                yRange = [loadTiles.y1..(loadTiles.y2)]
            tileManager.fillTiles(level, xRange, yRange)
            if tileManager.previousContainer != null
                tileManager.parentContainer.removeChild(tileManager.previousContainer)


        nextLayer: () ->
            tiles = tileManager.getNextTiles()
            tileManager.zoomLevel += 1
            tileManager.replaceLayer(tiles)


        previousLayer: () ->
            tiles = tileManager.getPreviousTiles()
            tileManager.zoomLevel -= 1
            console.log tiles
            tileManager.replaceLayer(tiles)


        replaceLayer: (loadTiles=null) ->
            # Before replacing the layer store any information which will be replaced
            previousBounds = tileManager.stage.getBounds()
            oldLayerBounds = $.extend({}, tileManager.layerBounds)
            tileManager.loadedTiles = null

            # Load the new layer based on the stored zoomLevel
            tileManager.addLayer(tileManager.zoomLevel, loadTiles)

            # Convert the anchor point from the old layer and assign it to the new layer
            pc = tileManager.previousContainer
            newReg = {
                x: (pc.regX / oldLayerBounds.width) * tileManager.layerBounds.width,
                y: (pc.regY / oldLayerBounds.height) * tileManager.layerBounds.height
            }
            tileManager.currentContainer.regX = newReg.x
            tileManager.currentContainer.regY = newReg.y

            # Convert the scale factors from the old layer and adjust the new layer to be the same size
            tileManager.currentContainer.scaleX = previousBounds.width / tileManager.layerBounds.width
            tileManager.currentContainer.scaleY = previousBounds.height / tileManager.layerBounds.height
            
            # Since the new layer is now the same size with the same anchor point as the old layer
            # the coordinates from the old layer can be directly assigned to the new layer
            tileManager.currentContainer.x = pc.x
            tileManager.currentContainer.y = pc.y
            tileManager.stage.update()


        zoom: (e) ->
            tileManager.getDisplayedTiles()
            # Function to handle scroll wheel zooming
            e.preventDefault();

            if Math.max(-1, Math.min(1, (e.wheelDelta || -e.detail || -e.deltaY))) > 0
                zoom = 1.1
            else
                zoom = 1/1.1

            if (tileManager.currentContainer.scaleX > 1.1 || tileManager.currentContainer.scaleY > 1.1) && zoom > 1
                if tileManager.zoomLevel < tileManager.maxZoom
                    tileManager.nextLayer()
            else if (tileManager.currentContainer.scaleX < 0.9 || tileManager.currentContainer.scaleY < 0.9) && zoom < 1
                if tileManager.zoomLevel > 0
                    tileManager.previousLayer()
            else
                # Get the current mouse position in local coordinates
                local = tileManager.currentContainer.globalToLocal(tileManager.stage.mouseX, tileManager.stage.mouseY)
                # Assign the local mouse position as the new anchor point so we can zoom around the mouse
                tileManager.currentContainer.regX = local.x
                tileManager.currentContainer.regY = local.y
                # move the view so that the mouse is centered
                tileManager.currentContainer.x = stage.mouseX
                tileManager.currentContainer.y = stage.mouseY
                # Double check that the user isn't zooming away from the plot
                bounds = stage.getBounds()
                if bounds.width > tile_size || zoom > 1
                    tileManager.currentContainer.scaleX *= zoom
                if bounds.height > tile_size || zoom > 1
                    tileManager.currentContainer.scaleY *= zoom
                stage.update()
            tileManager.canvas[0].dispatchEvent(viewportUpdate)


        fillTiles: (level, xRange, yRange) ->
            console.log "Range: " + String(xRange) + " " + String(yRange)
            for x in xRange
                for y in yRange
                    if !tileManager.isLoaded(x, y)
                        url = tileManager.tmsUrl.replace('{z}', level).replace('{x}', x).replace('{y}', y)
                        tile = new createjs.Bitmap(url)
                        tile.set {
                            x: x * tileManager.tileSize,
                            y: y * tileManager.tileSize
                        }
                        tileManager.currentContainer.addChild(tile)
                        tileManager.setLoaded(x, y)
                        console.log "Added: " + url
                        tile.image.onload = () ->
                            stage.update()


        updateViewport: () ->
            displayed = tileManager.getDisplayedTiles()
            xRange = [(displayed.x1)..(displayed.x2)]
            yRange = [(displayed.y1)..(displayed.y2)]
            tileManager.fillTiles(tileManager.zoomLevel, xRange, yRange)     
    }
    tileManager.addLayer()

    # $.getJSON("tiles2/fig.json", (json) ->
    plotManager = {
        tileManager: tileManager,
        axisSize: 50,
        plotContainer: plotContainer,
        canvas: canvas,
        x: null,
        y: null,
        xAxis: null,
        yAxis: null,
        xObj: null,
        yObj: null,
        axesUpdateTimeout: null,
        # attributes: json
        attributes: {"x_range": [1507038633.66, 1509615600.44], "title": "", "colorbar": ["#440154", "#482878", "#3e4989", "#31688e", "#26828e", "#1f9e89", "#35b779", "#6ece58", "#b5de2b", "#fde725"], "xlabel": "", "ylabel": "", "clim": [0.171, 9.9652], "y_range": [149.738, 0.0]},
        initAxes: () ->
            yElem = $('<svg class="yAxis" width="' + plotManager.axisSize + '" height="' + (canvas.height() + 10) + '"></svg>')
            yElem.css('position', 'absolute').css("top", 0).css("left", 0)
            plotManager.plotContainer.prepend(yElem)
            plotManager.plotContainer.css("padding-left", plotManager.axisSize)

            y = d3.scaleLinear()
                .domain(plotManager.attributes['y_range'])
                .range([canvas.height(), 0])
            plotManager.y = y

            yAxis = d3.select(yElem[0])
            plotManager.yAxis = yAxis

            plotManager.yObj = d3.axisLeft(y).ticks(10, "s")
            yAxis.append("g")
                .attr("transform", "translate(" + (plotManager.axisSize - 1) + ",10)")
                .attr("class", "axis")
                .call(plotManager.yObj)


            xElem = $('<svg class="xAxis" width="' + canvas.width() + '" height="' + plotManager.axisSize + '"></svg>')
            xElem.css('position', 'absolute').css("top", canvas.height() + 10).css("left", plotManager.axisSize - 1)
            plotManager.plotContainer.append(xElem)
            plotManager.plotContainer.css("padding-bottom", plotManager.axisSize)

            x = d3.scaleLinear()
                .domain([plotManager.attributes['x_range'][1], plotManager.attributes['x_range'][0]])
                .range([canvas.width(), 0])
            plotManager.x = x
            
            xAxis = d3.select(xElem[0])
            plotManager.xAxis = xAxis

            plotManager.xObj = d3.axisBottom(x).ticks(10, "s")

            xAxis.append("g")
                .attr("transform", "translate(0,0)")
                .attr("class", "axis")
                .call(plotManager.xObj)
            tileManager.canvas[0].addEventListener('viewportUpdate', (e) ->
                if plotManager.axesUpdateTimeout
                    return
                else
                    plotManager.axesUpdateTimeout = setTimeout((() ->
                        plotManager.updateAxes()
                        clearTimeout(plotManager.axesUpdateTimeout)
                        plotManager.axesUpdateTimeout = null
                        ), 300)
            )
            # tileManager.canvas[0].addEventListener('viewportUpdate', plotManager.updateAxes)


        updateAxes: () ->
            tileManager = plotManager.tileManager
            viewBounds = tileManager.getView()
            console.log(viewBounds)

            xRange = plotManager.attributes['x_range']
            xDiff = xRange[1] - xRange[0]

            yRange = plotManager.attributes['y_range']
            yDiff = yRange[0] - yRange[1]


            axesBounds = {
                x1: (viewBounds.x2 / tileManager.layerBounds.width) * xDiff + xRange[0],
                y1: (viewBounds.y2 / tileManager.layerBounds.height) * yDiff + yRange[1]
                x2: (viewBounds.x1 / tileManager.layerBounds.width) * xDiff + xRange[0],
                y2: (viewBounds.y1 / tileManager.layerBounds.height) * yDiff + yRange[1],
            }

            plotManager.x.domain([axesBounds.x1, axesBounds.x2])
            plotManager.y.domain([axesBounds.y1, axesBounds.y2])

            container = d3.select(plotContainer[0])

            container.select('.xAxis').select('.axis').call(plotManager.xObj)
            container.select('.yAxis').select('.axis').call(plotManager.yObj)
    }
    plotManager.initAxes()
    tileManager.canvas[0].addEventListener('viewportUpdate', plotManager.updateAxes)

    mode = 'pan'
    if mode == 'pan'
        stage.addEventListener 'stagemousedown', (e) ->
            offset =
                x: tileManager.currentContainer.x - e.stageX,
                y: tileManager.currentContainer.y - e.stageY
            stage.addEventListener "stagemousemove", (ev) ->
                tileManager.currentContainer.x = ev.stageX + offset.x
                tileManager.currentContainer.y = ev.stageY + offset.y
                stage.update()
                plotManager.updateAxes()
            stage.addEventListener "stagemouseup", ->
                tileManager.updateViewport()
                tileManager.stage.update()
                stage.removeAllEventListeners("stagemousemove")
                plotManager.updateAxes()
    else if mode == 'select'
        # TODO add an interaction mode that lets the user select a region of the x-axis
        console.log 'yo'

    canvas[0].addEventListener('wheel', tileManager.zoom, false)
