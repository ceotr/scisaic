$(window).on "load", ->
    tms_url = "tiles/{z}/{x}/{y}.png"
    starting_zoom = 0
    max_zoom = 4
    tile_size = 720

    canvas = $('#plot')
    stage = new createjs.Stage(canvas[0])

    starting_tile = tms_url.replace('{z}', starting_zoom).replace('{x}', '0').replace('{y}', '0')
    # container = new createjs.Container()
    container = null

    # tile = new createjs.Bitmap(starting_tile)
    # container.addChild(tile)
    # stage.addChild(container)
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
        addLayer: (level=this.zoomLevel) ->
            this.previousContainer = this.currentContainer
            this.currentContainer = new createjs.Container()
            container = this.currentContainer
            stage.addChild(this.currentContainer)
            console.log container
            bounds = stage.getBounds()
            tileShape = {
                x: 0,
                y: 0
            }
            for x in [0..2**(level-1)]
                for y in [0..2**(level-1)]
                    console.log(x,y)     
                    url = this.tmsUrl.replace('{z}', level).replace('{x}', x).replace('{y}', y)
                    tile = new createjs.Bitmap(url)
                    tile.set {
                        x: x * this.tileSize,
                        y: y * this.tileSize
                    }
                    this.currentContainer.addChild(tile)
                    tile.image.onload = () ->
                        stage.update()
            if this.previousContainer != null
                this.previousContainer.visible = false
        zoom: (zoom) ->
            local = container.globalToLocal(stage.mouseX, stage.mouseY)
            container.regX = local.x
            container.regY = local.y
            container.x = stage.mouseX
            container.y = stage.mouseY
            bounds = stage.getBounds()
            if bounds.width > tile_size || zoom > 1
                container.scaleX *= zoom
            if bounds.height > tile_size || zoom > 1
                container.scaleY *= zoom
        
    }
    tileManager.addLayer()
    tileManager.addLayer(4)

    # tile.image.onload = () ->
    #     stage.update()

    stage.addEventListener 'stagemousedown', (e) ->
        console.log(container.x/container.scaleX, container.y/container.scaleY)

        offset =
            x: container.x - e.stageX,
            y: container.y - e.stageY
        stage.addEventListener "stagemousemove", (ev) ->
            container.x = ev.stageX + offset.x
            container.y = ev.stageY + offset.y
            stage.update()
        stage.addEventListener "stagemouseup", ->
            stage.removeAllEventListeners("stagemousemove")

    MouseWheelHandler = (e) ->
        if Math.max(-1, Math.min(1, (e.wheelDelta || -e.detail))) > 0
            zoom = 1.1
        else
            zoom = 1/1.1

        # local = stage.globalToLocal(stage.mouseX, stage.mouseY)
        local = container.globalToLocal(stage.mouseX, stage.mouseY)
        # stage.regX = local.x
        # stage.regY = local.y
        container.regX = local.x
        container.regY = local.y
        # stage.x=stage.mouseX
        # stage.y=stage.mouseY
        container.x = stage.mouseX
        container.y = stage.mouseY
        # stage.scaleX = stage.scaleY *= zoom
        bounds = stage.getBounds()
        if bounds.width > tile_size || zoom > 1
            container.scaleX *= zoom
        if bounds.height > tile_size || zoom > 1
            container.scaleY *= zoom
        stage.update()

    canvas[0].addEventListener('wheel', MouseWheelHandler, false)
