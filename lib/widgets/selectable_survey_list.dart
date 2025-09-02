import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/survey_response.dart';
import 'package:surveyapp/widgets/custom_stream_builder.dart';

class SelectableSurveyList extends StatelessWidget {
  final Function(SurveyResponse survey) onSelect;
  final ScrollPhysics? physics;
  final SurveyResponse? selected;
  final ScrollController? scrollController;
  const SelectableSurveyList({
    super.key,
    required this.onSelect,
    this.selected,
    this.scrollController,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return CustomStreamBuilder(
        collection: 'responses',
        expand: 'form',
        fromMap: (Map<String, dynamic> json) => SurveyResponse.fromJson(json),
        builder: (BuildContext context, List<SurveyResponse> data) {
          return ListView.builder(
              itemCount: data.length,
              physics: physics,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              controller: scrollController,
              itemBuilder: (context, index) {
                final survey = data[index];
                final isSelected = selected?.id == survey.id;
                final area = survey.mappedArea;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => onSelect(survey),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Survey ${survey.id.substring(0, 8)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: Colors.blue),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${area.boundaryPoints.length} points',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.crop_free,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${((area.area ?? 0) / 10000).toStringAsFixed(2)} ha',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Created: ${DateFormat.MMMEd().format(survey.created)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
        });
  }
}
