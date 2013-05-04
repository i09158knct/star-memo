chai = require 'chai'
expect = chai.expect
assert = chai.assert
Star = require '../../models/star'


describe 'Star', ->
  describe 'static', ->
    describe 'fetchLastUpdatedTime', ->
      it 'should be function', ->
        expect(Star.fetchLastUpdatedTime).to.be.a 'function'
