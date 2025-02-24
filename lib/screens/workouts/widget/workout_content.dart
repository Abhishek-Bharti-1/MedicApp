import 'package:medicapp/core/const/color_constants.dart';
import 'package:medicapp/core/const/data_constants.dart';
import 'package:medicapp/data/workout_data.dart';
import 'package:medicapp/screens/workouts/widget/workout_card.dart';
import 'package:flutter/material.dart';

class WorkoutContent extends StatelessWidget {
  WorkoutContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        // margin: EdgeInsets.only(top: 50),
        color: ColorConstants.homeBackgroundColor,
        height: double.infinity,
        width: double.infinity,
        child: _createHomeBody(context),
      ),
    );
  }

  Widget _createHomeBody(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text('Statistics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 5),
        // Expanded(
        //   child: ListView(
        //     children: DataConstants.workouts
        //         .map(
        //           (e) => _createWorkoutCard(e),
        //         )
        //         .toList(),
        //   ),
        // ),
      ],
    );
  }

  Widget _createWorkoutCard(WorkoutData workoutData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: WorkoutCard(workout: workoutData),
    );
  }
}
