Religion = {}

class WateryGod
WateryGod::prayTo = ->
  console.log 'pray for water'
WateryGod::name = ->
  console.log 'my name is Water'
Religion.WateryGod = WateryGod

class AncientGods
AncientGods::prayTo = ->
  console.log 'pray to ancient gods muthafucka'
Religion.AncientGods = AncientGods

class DefaultGods
DefaultGods::prayTo = ->
Religion.DefaultGods = DefaultGods

# module.exports = Religion

module.exports =
  watery: WateryGod
  ancient: AncientGods
  defaults: DefaultGods
