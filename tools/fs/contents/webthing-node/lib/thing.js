/**
 * High-level Thing base class implementation.
 */

'use strict';

/**
 * A Web Thing.
 */
function Thing(name, type, description) {
  /**
   * Initialize the object.
   *
   * @param {String} name The thing's name
   * @param {String} type (Optional) The thing's type
   * @param {String} description (Optional) Description of the thing
   */
  {
    this.name = name;
    this.type = type || 'thing';
    this.description = description || '';
    this.properties = {};
    this.subscribers = [];
    this.hrefPrefix = '';
    this.uiHref = null;
  }

  /**
   * Return the thing state as a Thing Description.
   *
   * @returns {Object} Current thing state
   */
  this.asThingDescription = function() {
    var thing = {
      name: this.name,
      href: this.hrefPrefix ? this.hrefPrefix : '/',
      type: this.type,
      properties: this.getPropertyDescriptions(),
      links: [
        {
          rel: 'properties',
          href: this.hrefPrefix + '/properties',
        },
       ],
    };

    if (this.uiHref) {
      thing.links.push({
        rel: 'alternate',
        mediaType: 'text/html',
        href: this.uiHref,
      });
    }

    if (this.description) {
      thing.description = this.description;
    }

    return thing;
  }

  /**
   * Get this thing's href.
   *
   * @returns {String} The href.
   */
  this.getHref = function() {
    if (this.hrefPrefix) {
      return this.hrefPrefix;
    }

    return '/';
  }

  /**
   * Get this thing's UI href.
   *
   * @returns {String|null} The href.
   */
  this.getUiHref = function() {
    return this.uiHref;
  }

  /**
   * Set the prefix of any hrefs associated with this thing.
   *
   * @param {String} prefix The prefix
   */
  this.setHrefPrefix = function(prefix) {
    this.hrefPrefix = prefix;

    for (var property in this.properties) {
      property = this.properties[property];
      property.setHrefPrefix(prefix);
    }

  }

  /**
   * Set the href of this thing's custom UI.
   *
   * @param {String} href The href
   */
  this.setUiHref = function(href) {
    this.uiHref = href;
  }

  /**
   * Get the name of the thing.
   *
   * @returns {String} The name.
   */
  this.getName = function() {
    return this.name;
  }

  /**
   * Get the type of the thing.
   *
   * @returns {String} The type.
   */
  this.getType = function() {
    return this.type;
  }

  /**
   * Get the description of the thing.
   *
   * @returns {String} The description.
   */
  this.getDescription = function() {
    return this.description;
  }

  /**
   * Get the thing's properties as an object.
   *
   * @returns {Object} Properties, i.e. name -> description
   */
  this.getPropertyDescriptions = function() {
    var descriptions = {};
    for (var name in this.properties) {
      descriptions[name] = this.properties[name].asPropertyDescription();
    }

    return descriptions;
  }

  /**
   * Add a property to this thing.
   *
   * @param {Object} property Property to add
   */
  this.addProperty = function(property) {
    property.setHrefPrefix(this.hrefPrefix);
    this.properties[property.name] = property;
  }

  /**
   * Remove a property from this thing.
   *
   * @param {Object} property Property to remove
   */
  this.removeProperty = function(property) {
    if (this.properties.hasOwnProperty(property.name)) {
      delete this.properties[property.name];
    }
  }

  /**
   * Find a property by name.
   *
   * @param {String} propertyName Name of the property to find
   *
   * @returns {(Object|null)} Property if found, else null
   */
  this.findProperty = function(propertyName) {
    if (this.properties.hasOwnProperty(propertyName)) {
      return this.properties[propertyName];
    }

    return null;
  }

  /**
   * Get a property's value.
   *
   * @param {String} propertyName Name of the property to get the value of
   *
   * @returns {*} Current property value if found, else null
   */
  this.getProperty = function(propertyName) {
    var prop = this.findProperty(propertyName);
    if (prop) {
      return prop.getValue();
    }

    return null;
  }

  /**
   * Determine whether or not this thing has a given property.
   *
   * @param {String} propertyName The property to look for
   *
   * @returns {Boolean} Indication of property presence
   */
  this.hasProperty = function(propertyName) {
    return this.properties.hasOwnProperty(propertyName);
  }

  /**
   * Set a property value.
   *
   * @param {String} propertyName Name of the property to set
   * @param {*} value Value to set
   */
  this.setProperty = function(propertyName, value) {
    var prop = this.findProperty(propertyName);
    if (!prop) {
      return;
    }

    prop.setValue(value);
  }

  /**
   * Notify all subscribers of a property change.
   *
   * @param {Object} property The property that changed
   */
  this.propertyNotify = function(property) {

    var object =  {
      messageType: 'propertyStatus',
      data: {}
    };
    object.data[property.name] = property.getValue();
    var message = JSON.stringify(object);

    for (var idx; idx < this.subscribers.length; idx++) {
      var subscriber = this.subscribers[idx];
      try {
        subscriber.send(message);
      } catch (e) {
        // do nothing
      }
    }
  }
}

module.exports = Thing;
