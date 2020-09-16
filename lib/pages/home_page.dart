import 'dart:io';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pie_chart/pie_chart.dart';


class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Band> bands = [
    // Band(id: '1', name: 'Metalica', votes: 4),
    // Band(id: '2', name: 'Queen', votes: 1),
    // Band(id: '3', name: 'Héroes del silencio', votes: 3),
    // Band(id: '4', name: 'Bon Jovi', votes: 5),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands( dynamic payload) {

    this.bands = (payload as List)
        .map((band) => Band.fromMap(band))
        .toList();

        setState(() {
          
        });

  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context);
    socketService.socket.off('active-bands');
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('BandNames', style: TextStyle(color:Colors.black87,),)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: EdgeInsets.only( right: 10 ),
            child: 
            ( socketService.serverStatus == ServerStatus.Online ) ? 
            Icon(Icons.check_circle, color: Colors.blue[300],) :
            Icon(Icons.highlight_off, color: Colors.red,)
          )
        ],
      ),
      body: Column(
        children: [
          _showGraph(context),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, i) {
              return  _bandTile(bands[i]);
            },)
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        elevation: 1,
        onPressed: addNewBand,
      ),
   );
  }

  Widget _bandTile(Band band) {

    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: ( _ ) => socketService.emit('delete-band', {'id': band.id}),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.white,),
              Text('Delete Band', style: TextStyle(color: Colors.white),),
            ],
          ),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text( band.name.substring(0,2) ),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text('${ band.votes }' , style: TextStyle( fontSize: 20,),),
        onTap: () => socketService.socket.emit('vote-band', { 'id': band.id }),
      ),
    );
  }

  addNewBand() {

    final textController = new TextEditingController();
    if ( Platform.isAndroid ) {
      return showDialog(
        context: context,
        builder: ( _ ) {
          return AlertDialog(
            title: Text('New Band Name'),
            content: TextField(
              controller: textController,
            ),
            actions: <Widget>[
              MaterialButton(
                child: Text('Add'),
                elevation: 5,
                textColor: Colors.blue,
                onPressed: () => addBandToList(textController.text),
              ),
            ],
          );
        }
      );
    }

    showCupertinoDialog(
      context: context, 
      builder: ( _ ) {
        return CupertinoAlertDialog(
          title: Text('New Band Name'),
          content: CupertinoTextField(
            controller: textController,
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Add'),
              onPressed: () => addBandToList( textController.text ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text('Dismiss'),
              onPressed: () => Navigator.pop(context),

            )
          ],
        );
      },
    );
  }

  void addBandToList( String name) {

    if (name.length > 1 ) {
      // podemos agregar
      // emitir: crearBanda add-band
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', { 'name': name});
    }

    Navigator.pop(context);

  }

  Widget _showGraph(context) {

    final screenSize = MediaQuery.of(context).size;

    Map<String, double> dataMap = new Map();

    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    final List<Color> colorList = [
      Colors.blue[50],
      Colors.blue[200],
      Colors.pink[50],
      Colors.pink[200],
      Colors.yellow[50],
      Colors.yellow[200]
    ];

    return Container(
      width: screenSize.width * 0.96,
      height: 200,
      child: PieChart(
        dataMap: dataMap,
        animationDuration: Duration(milliseconds: 800),
        chartValuesOptions: ChartValuesOptions(
          showChartValuesInPercentage: true,
          showChartValues: true,
          showChartValuesOutside: false
        ),
        chartType: ChartType.ring,
        colorList: colorList,
      ),
    );
  }
}