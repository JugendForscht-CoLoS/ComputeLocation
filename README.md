# ComputeLocation

Zusammenfassung
----------------------

ComputeLocation ist ein Swift-Package zur Standortsbestimmung des Anwenders. Es handelt sich hierbei um ein System, welches nicht auf GPS oder ähnlichen Satelliten Systemen basiert.
Der Standort des Benutzers wird mit Hilfe mathematischer Methoden anhand des Sonnenstands berechnet.

Verwendung
--------------

ComputeLocation stellt Methoden zur manuellen und automatischen Standortsberechnung bereit. Durch manuelle Eingabe von zwei aufeinanderfolgenden Sonnenständen, kann der Standort des Benutzers bestimmt werden. Bei der automatischen Variante, handelt es sich um eine BLE-Schnittstelle um einen Messroboter zu verbinden. Sobald dieser neue Messungen bereit stellt, wird der Standort automatisch aktualisiert.

Dokumentation
-----------------
#### CpLLocationManager: `class CpLLocationManager`

###### Initializers:

* `init(characteristic: CpLCharacteristicLink, on peripheral: CBPeripheral, queue: DispatchQueue?, delegate: CpLLocationManagerDelegate?)`

###### Fields:

* `var locations: [CLLocationCoordinate2D] {get}`
*  `var delegate: CpLLocationManagerDelegate?`

###### Methods

* `static func getCoordinates(azimuts: (Double, Double), elevations: (Double, Double), time: Int, date: Int) -> CLLocationCoordinate2D`
* `func startUpdatingLocation()`

#### CpLLocationManagerDelegate: `protocol CpLLocationManagerDelegate`

* `func locationManager(_ locationManager: CpLLocationManager, didUpdateLocations locations: [CLLocationCoordinate2D])`

#### CpLCharacteristicLink: `struct CpLCharacteristicLink`

###### Initializers:

* `init(service: CBUUID, characteristic: CBUUID)`

###### Fields:

* `let service: CBUUID`
* `let characteristic: CBUUID`
