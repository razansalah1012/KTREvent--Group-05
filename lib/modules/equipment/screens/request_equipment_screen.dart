import 'package:flutter/material.dart';
import '../services/equipment_service.dart';

class RequestEquipmentScreen extends StatefulWidget {
  const RequestEquipmentScreen({super.key});

  @override
  State<RequestEquipmentScreen> createState() =>
      _RequestEquipmentScreenState();
}

class _RequestEquipmentScreenState
    extends State<RequestEquipmentScreen> {

  final _equipmentController = TextEditingController();
  final _quantityController = TextEditingController();

  final EquipmentService service = EquipmentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Equipment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: _equipmentController,
              decoration: const InputDecoration(
                labelText: "Equipment Name",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: "Quantity",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {

                await service.requestEquipment(
                  equipmentName:
                  _equipmentController.text,
                  quantity:
                  int.parse(_quantityController.text),
                  requester: "Student",
                );

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content:
                    Text("Request Submitted"),
                  ),
                );
              },
              child: const Text("Submit Request"),
            )
          ],
        ),
      ),
    );
  }
}
