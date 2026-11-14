abstract class Cleanable {
  void descaleMachine();
}

mixin SmartWifiControl {
  bool isConnected = false;

  void connectWifi(String networkName) {
    isConnected = true;
    print("Connected to Wi-Fi network '$networkName' for remote brewing.");
  }
}

class CoffeeMaker implements Cleanable {
  String brand;
  int maxTankCapacity;
  int _waterLevel;
  List<String> brewHistory = [];

  CoffeeMaker(this.brand, this.maxTankCapacity, this._waterLevel);

  int get waterLevel => _waterLevel;

  bool consumeWater(int cups) {
    if (cups <= 0) {
      print("[$brand] Error: Request at least 1 cup.");
      return false;
    }
    if (cups > _waterLevel) {
      print(
        "[$brand] Insufficient water ($_waterLevel cups left) for $cups cup(s).",
      );
      return false;
    }
    _waterLevel -= cups;
    return true;
  }

  void refillWater(int cups) {
    if (cups <= 0) {
      print("[$brand] Error: Refill amount must be at least 1 cup.");
      return;
    }
    if (_waterLevel + cups > maxTankCapacity) {
      _waterLevel = maxTankCapacity;
      print(
        "[$brand] Tank filled to maximum capacity ($maxTankCapacity cups).",
      );
    } else {
      _waterLevel += cups;
      print(
        "[$brand] Added $cups cup(s). Current water level: $_waterLevel/$maxTankCapacity.",
      );
    }
  }

  void brewCoffee(String coffeeType, int cupsRequested) {
    if (consumeWater(cupsRequested)) {
      brewHistory.add("$cupsRequested cup(s) of $coffeeType");
      print(
        "[$brand] Brewing $cupsRequested cup(s) of $coffeeType... Done! Water left: $_waterLevel.",
      );
    }
  }

  @override
  void descaleMachine() {
    print("[$brand] Running standard descaling cycle... Complete.");
  }

  void showStatus() {
    print(
      "Machine: $brand | Water: $_waterLevel/$maxTankCapacity cups | Orders: ${brewHistory.length}",
    );
  }
}

class EspressoMachine extends CoffeeMaker with SmartWifiControl {
  int pressureBars;

  EspressoMachine(
    String brand,
    int maxTankCapacity,
    int waterLevel,
    this.pressureBars,
  ) : super(brand, maxTankCapacity, waterLevel);

  @override
  void brewCoffee(String coffeeType, int cupsRequested) {
    if (consumeWater(cupsRequested)) {
      brewHistory.add(
        "$cupsRequested shot(s) of $coffeeType ($pressureBars bars)",
      );
      print(
        "[$brand] Heating boiler to $pressureBars bars... Extracting $cupsRequested shot(s) of $coffeeType with rich crema! Water left: $_waterLevel.",
      );
    }
  }

  Future<String> brewRemoteOrderAsync(
    String coffeeType,
    int cupsRequested,
  ) async {
    if (!isConnected) {
      return "[$brand] Remote brew failed: Machine is not connected to Wi-Fi.";
    }

    await Future.delayed(Duration(seconds: 2));

    if (consumeWater(cupsRequested)) {
      brewHistory.add("$cupsRequested remote shot(s) of $coffeeType");
      return "[$brand] Remote brew complete! $cupsRequested shot(s) of $coffeeType ready. Water left: $_waterLevel.";
    } else {
      return "[$brand] Remote brew cancelled due to insufficient water.";
    }
  }

  @override
  void descaleMachine() {
    print(
      "[$brand] Flushing high-pressure steam wand and group head... Descaled.",
    );
  }
}

class DripCoffeeMaker extends CoffeeMaker {
  bool keepWarmPlateOn;

  DripCoffeeMaker(
    String brand,
    int maxTankCapacity,
    int waterLevel,
    this.keepWarmPlateOn,
  ) : super(brand, maxTankCapacity, waterLevel);

  @override
  void brewCoffee(String coffeeType, int cupsRequested) {
    if (consumeWater(cupsRequested)) {
      keepWarmPlateOn = true;
      brewHistory.add("$cupsRequested cup(s) of $coffeeType (Carafe)");
      print(
        "[$brand] Dripping $cupsRequested cup(s) of $coffeeType into glass carafe... Warming plate ON! Water left: $_waterLevel.",
      );
    }
  }

  @override
  void descaleMachine() {
    print(
      "[$brand] Soaking filter basket and carafe in cleaning solution... Descaled.",
    );
  }
}

void processSafeOrder(
  CoffeeMaker machine,
  String coffeeType,
  String rawCupInput,
) {
  try {
    int cups = int.parse(rawCupInput);
    machine.brewCoffee(coffeeType, cups);
  } catch (e) {
    print(
      "[Input Error] '$rawCupInput' is not a valid cup count. Please enter a whole number.",
    );
  }
}

Future<void> main() async {
  print("=== Smart Coffee Maker System (Milestone 2) ===\n");

  EspressoMachine espressoUnit = EspressoMachine(
    "Breville Barista Pro",
    6,
    5,
    9,
  );
  DripCoffeeMaker dripUnit = DripCoffeeMaker("Moccamaster KBGV", 10, 8, false);

  espressoUnit.connectWifi("Kitchen_5G");

  List<CoffeeMaker> machines = [espressoUnit, dripUnit];

  print("\n--- Polymorphic Brewing & Error Handling ---");
  for (CoffeeMaker machine in machines) {
    processSafeOrder(machine, "House Blend", "2");
  }
  processSafeOrder(dripUnit, "Decaf", "invalid_number");

  print("\n--- Asynchronous Remote Order ---");
  Future<String> pendingOrder = espressoUnit.brewRemoteOrderAsync(
    "Caramel Macchiato",
    2,
  );
  print("Main thread remains responsive while espresso boiler heats up...");
  dripUnit.refillWater(3);

  String remoteResult = await pendingOrder;
  print(remoteResult);

  print("\n--- Maintenance & Fleet Summary ---");
  for (CoffeeMaker machine in machines) {
    machine.descaleMachine();
    machine.showStatus();
    print("  History: ${machine.brewHistory}");
  }
}
