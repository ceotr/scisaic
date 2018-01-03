$(window).on "load", ->
    tms_url = "tiles/{z}/{x}/{y}.png"
    starting_zoom = 0
    max_zoom = 4
    tile_size = 720

    canvas = $('#plot')
    stage = new createjs.Stage(canvas[0])

    starting_tile = tms_url.replace('{z}', starting_zoom).replace('{x}', '0').replace('{y}', '0')
    container = null

    context = stage.canvas.getContext("2d")
    context.imageSmoothingEnabled = false


    tileManager = {
        stage: stage,
        canvas: canvas,
        currentContainer: container,
        previousContainer: null,
        zoomLevel: starting_zoom,
        maxZoom: max_zoom,
        tmsUrl: tms_url,
        tileSize: tile_size,
        layerBounds: {
            width: null,
            height: null
        },

        getView: () ->
            cSize = {
                width: canvas.width(),
                height: canvas.height()
            }
            container = tileManager.currentContainer

            # bounds = tileManager.stage.getBounds()
            # bbox = [
            #     {
            #         x: Math.floor((bounds.x * -1) / tileManager.tileSize),
            #         y: Math.floor(bounds.y / tileManager.tileSize)
            #     },
            #     {
            #         x: Math.ceil(((bounds.x * -1) + cSize.width) / tileManager.tileSize),
            #         y: Math.ceil((bounds.y + cSize.height) / tileManager.tileSize)
            #     }
            # ]
            # console.log bbox

        getDisplayedTiles: () ->
            console.log tileManager.currentContainer


        addLayer: (level=tileManager.zoomLevel) ->
            tileManager.previousContainer = tileManager.currentContainer
            tileManager.currentContainer = new createjs.Container()
            container = tileManager.currentContainer
            tileManager.layerBounds.width = tileManager.layerBounds.height = tileManager.tileSize * (2**level)
            tileManager.currentContainer.setBounds(0, 0, tileManager.layerBounds.width, tileManager.layerBounds.height)
            stage.addChild(tileManager.currentContainer)
            bounds = stage.getBounds()
            tileShape = {
                x: 0,
                y: 0
            }
            for x in [0..2**level - 1]
                for y in [0..2**level - 1]
                    url = tileManager.tmsUrl.replace('{z}', level).replace('{x}', x).replace('{y}', y)
                    tile = new createjs.Bitmap(url)
                    tile.set {
                        x: x * tileManager.tileSize,
                        y: y * tileManager.tileSize
                    }
                    tileManager.currentContainer.addChild(tile)
                    tile.image.onload = () ->
                        stage.update()
            if tileManager.previousContainer != null
                tileManager.stage.removeChild(tileManager.previousContainer)
                # tileManager.previousContainer.visible = false

        nextLayer: () ->
            tileManager.zoomLevel += 1
            tileManager.replaceLayer()

        previousLayer: () ->
            tileManager.zoomLevel -= 1
            tileManager.replaceLayer()

        replaceLayer: () ->
            # Before replacing the layer store any information which will be replaced
            previousBounds = tileManager.stage.getBounds()
            oldLayerBounds = $.extend({}, tileManager.layerBounds)

            # Load the new layer based on the stored zoomLevel
            tileManager.addLayer(tileManager.zoomLevel)

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
    }
    tileManager.addLayer()

    stage.addEventListener 'stagemousedown', (e) ->
        offset =
            x: container.x - e.stageX,
            y: container.y - e.stageY
        stage.addEventListener "stagemousemove", (ev) ->
            container.x = ev.stageX + offset.x
            container.y = ev.stageY + offset.y
            stage.update()
        stage.addEventListener "stagemouseup", ->
            stage.removeAllEventListeners("stagemousemove")

    canvas[0].addEventListener('wheel', tileManager.zoom, false)
