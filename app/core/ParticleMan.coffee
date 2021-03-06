CocoClass = require 'core/CocoClass'
utils = require 'core/utils'

module.exports = ParticleMan = class ParticleMan extends CocoClass

  constructor: ->
    return @unsupported = true unless Modernizr.webgl
    @renderer = new THREE.WebGLRenderer alpha: true
    $(@renderer.domElement).addClass 'particle-man'
    @scene = new THREE.Scene()
    @clock = new THREE.Clock()
    @particleGroups = []

  destroy: ->
    @detach()
    # TODO: figure out how to dispose everything
    # scene.remove(mesh)
    # mesh.dispose()
    # geometry.dispose()
    # material.dispose()
    # texture.dispose()
    super()

  attach: (@$el) ->
    return if @unsupported
    width = @$el.innerWidth()
    height = @$el.innerHeight()
    @aspectRatio = width / height
    @renderer.setSize(width, height)
    @$el.append @renderer.domElement
    @camera = camera = new THREE.OrthographicCamera(
      100 * -0.5,                 # Left
      100 * 0.5,                  # Right
      100 * 0.5 * @aspectRatio,   # Top
      100 * -0.5 * @aspectRatio,  # Bottom
      0,                          # Near frustrum distance
      1000                        # Far frustrum distance
    )
    @camera.position.set(0, 0, 100)
    @camera.up = new THREE.Vector3(0, 1, 0)  # http://stackoverflow.com/questions/14271672/moving-the-camera-lookat-and-rotations-in-three-js
    @camera.lookAt new THREE.Vector3(0, 0, 0)
    unless @started
      @started = true
      @render()

  detach: ->
    return if @unsupported
    @renderer.domElement.remove()
    @started = false

  render: =>
    return if @unsupported
    return if @destroyed
    return unless @started
    @renderer.render @scene, @camera
    dt = @clock.getDelta()
    for group in @particleGroups
      group.tick dt
    requestAnimationFrame @render
    #@countFPS()

  countFPS: ->
    @framesRendered ?= 0
    ++@framesRendered
    @lastFPS ?= new Date()
    now = new Date()
    if now - @lastFPS > 1000
      console.log @framesRendered, 'fps with', @particleGroups.length, 'particle groups.'
      @framesRendered = 0
      @lastFPS = now

  addEmitter: (x, y, kind="level-dungeon-premium") ->
    return if @unsupported
    console.log 'adding kind', kind
    options = $.extend true, {}, particleKinds[kind]
    options.group.texture = THREE.ImageUtils.loadTexture "/images/common/particles/#{options.group.texture}.png"
    scale = 100
    aspectRatio = @$el
    group = new SPE.Group options.group
    group.mesh.position.x = scale * (-0.5 + x)
    group.mesh.position.y = scale * (-0.5 + y) * @aspectRatio
    emitter = new SPE.Emitter options.emitter
    group.addEmitter emitter
    @particleGroups.push group
    @scene.add group.mesh
    group

  removeEmitter: (group) ->
    return if @unsupported
    @scene.remove group.mesh
    @particleGroups = _.without @particleGroups, group

  removeEmitters: ->
    return if @unsupported
    @removeEmitter group for group in @particleGroups.slice()
 
  #addTestCube: ->
    #geometry = new THREE.BoxGeometry 5, 5, 5
    #material = new THREE.MeshLambertMaterial color: 0xFF0000
    #mesh = new THREE.Mesh geometry, material
    #@scene.add mesh
    #light = new THREE.PointLight 0xFFFF00
    #light.position.set 10, 0, 20
    #@scene.add light


hsl = (hue, saturation, lightness) ->
  new THREE.Color utils.hslToHex([hue, saturation, lightness])
vec = (x, y, z) ->
  new THREE.Vector3 x, y, z

defaults =
  group:
    texture: 'star'
    maxAge: 1.9
    radius: 0.75
    hasPerspective: 1
    colorize: 1
    transparent: 1
    alphaTest: 0.5
    depthWrite: false
    depthTest: true
    blending: THREE.NormalBlending
  emitter:
    type: "disk"
    particleCount: 100
    radius: 1
    position: vec 0, 0, 0
    positionSpread: vec 1, 0, 1
    acceleration: vec 0, 2, 0
    accelerationSpread: vec 0, 0, 0
    velocity: vec 0, 4, 0
    velocitySpread: vec 2, 2, 2
    sizeStart: 6
    sizeStartSpread: 1
    sizeMiddle: 4
    sizeMiddleSpread: 1
    sizeEnd: 2
    sizeEndSpread: 1
    angleStart: 0
    angleStartSpread: 0
    angleMiddle: 0
    angleMiddleSpread: 0
    angleEnd: 0
    angleEndSpread: 0
    angleAlignVelocity: false
    colorStart: hsl 0.55, 0.75, 0.75
    colorStartSpread: vec 0.3, 0.3, 0.3
    colorMiddle: hsl 0.55, 0.6, 0.5
    colorMiddleSpread: vec 0.2, 0.2, 0.2
    colorEnd: hsl 0.55, 0.5, 0.25
    colorEndSpread: vec 0.1, 0.1, 0.1
    opacityStart: 1
    opacityStartSpread: 0
    opacityMiddle: 0.75
    opacityMiddleSpread: 0
    opacityEnd: 0.25
    opacityEndSpread: 0
    duration: null
    alive: 1
    isStatic: 0

ext = (d, options) ->
  $.extend true, {}, d, options ? {}

particleKinds =
  'level-dungeon-premium': ext defaults
  'level-forest-premium': ext defaults,
    emitter:
      colorStart: hsl 0.56, 0.97, 0.5
      colorMiddle: hsl 0.56, 0.57, 0.5
      colorEnd: hsl 0.56, 0.17, 0.5
  'level-desert-premium': ext defaults,
    emitter:
      colorStart: hsl 0.56, 0.97, 0.5
      colorMiddle: hsl 0.56, 0.57, 0.5
      colorEnd: hsl 0.56, 0.17, 0.5
  'level-mountain-premium': ext defaults,
    emitter:
      colorStart: hsl 0.56, 0.97, 0.5
      colorMiddle: hsl 0.56, 0.57, 0.5
      colorEnd: hsl 0.56, 0.17, 0.5

particleKinds['level-dungeon-gate'] = ext particleKinds['level-dungeon-premium'],
  emitter:
    particleCount: 120
    velocity: vec 0, 6, 0
    colorStart: hsl 0.5, 0.75, 0.9
    colorMiddle: hsl 0.5, 0.75, 0.7
    colorEnd: hsl 0.5, 0.75, 0.3
    colorStartSpread: vec 1, 1, 1
    colorMiddleSpread: vec 1.5, 1.5, 1.5
    colorEndSpread: vec 2.5, 2.5, 2.5

particleKinds['level-dungeon-hero-ladder'] = ext particleKinds['level-dungeon-premium'],
  emitter:
    particleCount: 90
    velocity: vec 0, 4, 0
    colorStart: hsl 0, 0.75, 0.7
    colorMiddle: hsl 0, 0.75, 0.5
    colorEnd: hsl 0, 0.75, 0.3

particleKinds['level-forest-gate'] = ext particleKinds['level-forest-premium'],
  emitter:
    particleCount: 120
    velocity: vec 0, 8, 0
    colorStart: hsl 0.56, 0.97, 0.3
    colorMiddle: hsl 0.56, 0.57, 0.3
    colorEnd: hsl 0.56, 0.17, 0.3
    colorStartSpread: vec 1, 1, 1
    colorMiddleSpread: vec 1.5, 1.5, 1.5
    colorEndSpread: vec 2.5, 2.5, 2.5

particleKinds['level-forest-hero-ladder'] = ext particleKinds['level-forest-premium'],
  emitter:
    particleCount: 90
    velocity: vec 0, 4, 0
    colorStart: hsl 0, 0.95, 0.3
    colorMiddle: hsl 0, 1, 0.5
    colorEnd: hsl 0, 0.75, 0.1

particleKinds['level-desert-gate'] = ext particleKinds['level-desert-premium'],
  emitter:
    particleCount: 120
    velocity: vec 0, 8, 0
    colorStart: hsl 0.56, 0.97, 0.3
    colorMiddle: hsl 0.56, 0.57, 0.3
    colorEnd: hsl 0.56, 0.17, 0.3
    colorStartSpread: vec 1, 1, 1
    colorMiddleSpread: vec 1.5, 1.5, 1.5
    colorEndSpread: vec 2.5, 2.5, 2.5

particleKinds['level-desert-hero-ladder'] = ext particleKinds['level-desert-premium'],
  emitter:
    particleCount: 90
    velocity: vec 0, 4, 0
    colorStart: hsl 0, 0.95, 0.3
    colorMiddle: hsl 0, 1, 0.5
    colorEnd: hsl 0, 0.75, 0.1

particleKinds['level-dungeon-gate'] = ext particleKinds['level-dungeon-premium'],
  emitter:
    particleCount: 120
    velocity: vec 0, 8, 0
    colorStart: hsl 0.56, 0.97, 0.3
    colorMiddle: hsl 0.56, 0.57, 0.3
    colorEnd: hsl 0.56, 0.17, 0.3
    colorStartSpread: vec 1, 1, 1
    colorMiddleSpread: vec 1.5, 1.5, 1.5
    colorEndSpread: vec 2.5, 2.5, 2.5

particleKinds['level-dungeon-hero-ladder'] = ext particleKinds['level-dungeon-premium'],
  emitter:
    particleCount: 90
    velocity: vec 0, 4, 0
    colorStart: hsl 0, 0.95, 0.3
    colorMiddle: hsl 0, 1, 0.5
    colorEnd: hsl 0, 0.75, 0.1
