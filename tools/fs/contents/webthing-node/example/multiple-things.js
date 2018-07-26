var index  = require('webthing');
var Property = index.Property;
var MultipleThings = index.server.MultipleThings;
var Thing = index.Thing;
var Value = index.Value;
var WebThingServer = index.server.WebThingServer;

/**
 * A dimmable light that logs received commands to stdout.
 */
function ExampleDimmableLight() {
{
    Thing.call(this, 'My Lamp', dimmableLight, 'A web connected lamp');

    this.addProperty(
      new Property(
        this,
        'on',
        new Value(true, (v) => console.log('On-State is now', v)),
        {
          '@type': 'OnOffProperty',
          label: 'On/Off',
          type: 'boolean',
          description: 'Whether the lamp is turned on',
        }));

    this.addProperty(
      new Property(
        this,
        'brightness',
        new Value(50, (v) => console.log('Brightness is now', v)),
        {
          '@type': 'BrightnessProperty',
          label: 'Brightness',
          type: 'number',
          description: 'The level of light from 0-100',
          minimum: 0,
          maximum: 100,
          unit: 'percent',
        }));

    this.addProperty(this.getOnProperty());
    this.addProperty(this.getLevelProperty());
  }

  this.getOnProperty = function() {
    return new Property(
      this,
      'on',
      new Value(true, function(v) { console.log('On-State is now', v);}),
      {type: 'boolean',
       description: 'Whether the lamp is turned on'});
  }

  this.getLevelProperty = function() {
    return new Property(
      this,
      'level',
      new Value(50, function(l) { console.log('New light level is', l);}),
      {type: 'number',
       description: 'The level of light from 0-100',
       minimum: 0,
       maximum: 100});
  }

  this.addProperty(this.getOnProperty());
  this.addProperty(this.getLevelProperty());
  
  return this;
}


/**
 * A humidity sensor which updates its measurement every few seconds.
 */
function FakeGpioHumiditySensor() {
  {
    var self = this;
    Thing.call(this, 'My Humidity Sensor',
          'multiLevelSensor',
          'A web connected humidity sensor');

    this.addProperty(
      new Property(this,
                   'on',
                   new Value(true),
                   {type: 'boolean',
                    description: 'Whether the sensor is on'}));

    this.level = new Value(0.0);
    this.addProperty(
      new Property(this,
                   'level',
                   this.level,
                   {type: 'number',
                    description: 'The current humidity in %',
                    unit: '%'}));

    // Poll the sensor reading every 3 seconds
    setInterval(function() {
      // Update the underlying value, which in turn notifies all listeners
      var newLevel = self.readFromGPIO();
      console.log('setting new humidity level:', newLevel);
      self.level.notifyOfExternalUpdate(newLevel);
    }, 3000);
  }

  /**
   * Mimic an actual sensor updating its reading every couple seconds.
   */
  this.readFromGPIO = function() {
    return 70.0 * Math.random() * (-0.5 + Math.random());
  }
}

function runServer() {
  // Create a thing that represents a dimmable light
  var light = new ExampleDimmableLight();

  // Create a thing that represents a humidity sensor
  var sensor = new FakeGpioHumiditySensor();

  // If adding more than one thing, use MultipleThings() with a name.
  // In the single thing case, the thing's name will be broadcast.
  var server = new WebThingServer(new MultipleThings([light, sensor],
                                                       'LightAndTempDevice'),
                                    8888);

  process.on('SIGINT', function() {
    server.stop();
    process.exit();
  });

  server.start();
}

runServer();
