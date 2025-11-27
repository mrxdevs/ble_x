import 'package:flutter/material.dart';

class PhoneConrolScreen extends StatefulWidget {
  const PhoneConrolScreen({super.key});

  @override
  State<PhoneConrolScreen> createState() => _PhoneConrolScreenState();
}

class _PhoneConrolScreenState extends State<PhoneConrolScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();

  void _onKeypadTap(String value) {
    setState(() {
      _phoneNumberController.text += value;
    });
  }

  void _onBackspace() {
    if (_phoneNumberController.text.isNotEmpty) {
      setState(() {
        _phoneNumberController.text = _phoneNumberController.text.substring(
          0,
          _phoneNumberController.text.length - 1,
        );
      });
    }
  }

  void _onCall() {
    // Implement call logic here
    print('Calling ${_phoneNumberController.text}...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Control')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                _phoneNumberController.text,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(20),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                for (var i = 1; i <= 9; i++) _buildKeypadButton(i.toString()),
                _buildKeypadButton('*'),
                _buildKeypadButton('0'),
                _buildKeypadButton('#'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _onBackspace,
                  icon: const Icon(Icons.backspace),
                  iconSize: 32,
                ),
                FloatingActionButton(
                  onPressed: _onCall,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.call),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String label) {
    return InkWell(
      onTap: () => _onKeypadTap(label),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
