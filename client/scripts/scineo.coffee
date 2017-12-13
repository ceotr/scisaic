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
        stage: stage
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

        zoom: (e) ->
            if Math.max(-1, Math.min(1, (e.wheelDelta || -e.detail))) > 0
                zoom = 1.1
            else
                zoom = 1/1.1

            if (tileManager.currentContainer.scaleX > 1 || tileManager.currentContainer.scaleY > 1) && zoom > 1
                if tileManager.zoomLevel < tileManager.maxZoom
                    previousBounds = tileManager.stage.getBounds()
                    console.log previousBounds
                    oldLayerBounds = $.extend({}, tileManager.layerBounds)

                    tileManager.zoomLevel += 1
                    tileManager.addLayer(tileManager.zoomLevel)

                    pc = tileManager.previousContainer
                    # newReg = pc.localToGlobal(pc.regX, pc.regY)
                    console.log "Old Reg:"
                    console.log(pc.regX, pc.regY)
                    console.log "Old Size:"
                    console.log(oldLayerBounds.width, oldLayerBounds.height)
                    console.log "New Size:"
                    console.log(tileManager.layerBounds.width, tileManager.layerBounds.height)
                    newReg = {
                        x: (pc.regX / oldLayerBounds.width) * tileManager.layerBounds.width,
                        y: (pc.regY / oldLayerBounds.height) * tileManager.layerBounds.height
                    }
                    tileManager.currentContainer.regX = newReg.x
                    tileManager.currentContainer.regY = newReg.y
                    console.log "New Reg:"
                    console.log(newReg.x, newReg.y)

                    # console.log tileManager.stage.getBounds()
                    # console.log tileManager.layerBounds

                    tileManager.currentContainer.scaleX = previousBounds.width / tileManager.layerBounds.width
                    tileManager.currentContainer.scaleY = previousBounds.height / tileManager.layerBounds.height
                    
                    oldBounds = pc.getBounds()
                    newPos = pc.localToGlobal(oldBounds.x, oldBounds.y)
                    # tileManager.currentContainer.x = newPos.x
                    # tileManager.currentContainer.y = newPos.y
                    tileManager.currentContainer.x = pc.x
                    tileManager.currentContainer.y = pc.y
                    tileManager.stage.update()
                    console.log(tileManager.stage.getBounds())
                    console.log("-------------")
            else
                local = tileManager.currentContainer.globalToLocal(tileManager.stage.mouseX, tileManager.stage.mouseY)
                tileManager.currentContainer.regX = local.x
                tileManager.currentContainer.regY = local.y
                tileManager.currentContainer.x = stage.mouseX
                tileManager.currentContainer.y = stage.mouseY
                bounds = stage.getBounds()
                if bounds.width > tile_size || zoom > 1
                    tileManager.currentContainer.scaleX *= zoom
                if bounds.height > tile_size || zoom > 1
                    tileManager.currentContainer.scaleY *= zoom
                stage.update()
        
    }
    tileManager.addLayer()

    stage.addEventListener 'stagemousedown', (e) ->
        # console.log "Yo"
        # console.log tileManager.stage.getBounds()
        # bounds = tileManager.currentContainer.getBounds()
        # console.log bounds
        # console.log tileManager.currentContainer.localToGlobal(bounds.x, bounds.y)
        # newBounds = tileManager.currentContainer.getBounds()
        # xRatio = tileManager.currentContainer.x / newBounds.width
        # yRatio = tileManager.currentContainer.y / newBounds.height
        # console.log(tileManager.currentContainer.x, tileManager.currentContainer.y)
        # console.log(xRatio, yRatio)
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
