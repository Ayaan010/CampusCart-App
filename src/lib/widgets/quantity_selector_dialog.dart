import 'package:flutter/material.dart';

class QuantitySelectorDialog extends StatefulWidget {
  final int maxQuantity;

  const QuantitySelectorDialog({Key? key, required this.maxQuantity})
    : super(key: key);

  @override
  State<QuantitySelectorDialog> createState() => _QuantitySelectorDialogState();
}

class _QuantitySelectorDialogState extends State<QuantitySelectorDialog> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Quantity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Available stock: ${widget.maxQuantity}'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (quantity > 1) {
                    setState(() {
                      quantity--;
                    });
                  }
                },
              ),
              Text('$quantity', style: const TextStyle(fontSize: 20)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (quantity < widget.maxQuantity) {
                    setState(() {
                      quantity++;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, quantity),
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}
