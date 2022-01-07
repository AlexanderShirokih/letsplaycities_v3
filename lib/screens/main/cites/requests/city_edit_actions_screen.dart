import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_edit_actions_bloc.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/main/cites/list/widgets/add_city_layout.dart';
import 'package:lets_play_cities/screens/main/cites/list/widgets/remove_city_layout.dart';
import 'package:lets_play_cities/screens/main/cites/list/widgets/rename_city_layout.dart';
import 'package:lets_play_cities/screens/main/cites/model/city_item.dart';

import '../model/city_edit_action.dart';

/// Screen that allows to send requests to edit, add or remove a city
class CityEditActionsScreen extends StatefulWidget {
  final CityEditAction action;
  final String? city;

  const CityEditActionsScreen({
    Key? key,
    required this.action,
    this.city,
  }) : super(key: key);

  @override
  State<CityEditActionsScreen> createState() => _CityEditActionsScreenState();
}

class _CityEditActionsScreenState extends State<CityEditActionsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cityNameController;
  late TextEditingController _reasonTextController;

  CountryEntity? _currentCountry;

  bool _showSendButton = false;
  CityItem? _originalItem;

  @override
  void initState() {
    _cityNameController = TextEditingController(text: widget.city)
      ..addListener(() {
        _revalidateForm();
      });

    _reasonTextController = TextEditingController()
      ..addListener(() {
        _revalidateForm();
      });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _cityNameController.dispose();
    _reasonTextController.dispose();
  }

  void _revalidateForm() {
    Future.delayed(Duration(milliseconds: 100), () async {
      setState(() {
        final currentCityItem = CityItem(
          _cityNameController.text,
          _currentCountry ?? CountryEntity('', 0, false),
        );

        // All fields are filled
        final isFieldsFilled = _formKey.currentState?.validate() == true;

        // Needs any changes to proceed
        final wantsChanges = widget.action == CityEditAction.Edit;

        // Any changes was made
        final hasAnyChanges = _originalItem != currentCityItem;

        _showSendButton = isFieldsFilled && (hasAnyChanges || !wantsChanges);
      });
    });
  }

  @override
  Widget build(BuildContext context) => buildWithLocalization(
        context,
        (l10n) => BlocProvider<CityEditActionsBloc>(
          create: (context) => CityEditActionsBloc(
            GetIt.instance.get(),
            GetIt.instance.get(),
            GetIt.instance.get(),
            widget.city,
          ),
          child: Scaffold(
            floatingActionButton: Builder(builder: (context) {
              return FloatingActionButton.extended(
                backgroundColor:
                    _showSendButton ? null : Theme.of(context).disabledColor,
                icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                label: Text('ОТПРАВИТЬ'),
                onPressed: _showSendButton
                    ? () {
                        context
                            .read<CityEditActionsBloc>()
                            .add(CityEditActionSend(
                              reason: _reasonTextController.text,
                              updatedCityName: _cityNameController.text,
                              updatedCountryCode:
                                  _currentCountry?.countryCode ?? 0,
                            ));
                      }
                    : null,
              );
            }),
            appBar: AppBar(
              title: Text(l10n.citiesRequest[_getTitleKey()]),
            ),
            body: BlocListener<CityEditActionsBloc, CityEditActionsState>(
              listener: (context, state) {
                if (state is CityNotFound) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Город с названием "${state.city}" не найден в базе данных'),
                    ),
                  );
                } else if (state is CityEditActionsData) {
                  setState(() {
                    _currentCountry ??= state.cityItem.country;
                    _originalItem = state.cityItem;
                  });
                }
              },
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 26.0,
                      right: 26.0,
                      top: 30,
                    ),
                    child: _buildContent(context, l10n),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildContent(BuildContext context, LocalizationService l10n) {
    switch (widget.action) {
      case CityEditAction.Edit:
        return RenameCityLayout(
          l10n: l10n,
          cityNameController: _cityNameController,
          reasonController: _reasonTextController,
          currentCountry: _currentCountry,
          onCountryChanged: (CountryEntity newEntity) {
            setState(() {
              _currentCountry = newEntity;
            });
            _revalidateForm();
          },
        );
      case CityEditAction.Remove:
        return RemoveCityLayout(
          l10n: l10n,
          reasonController: _reasonTextController,
        );
      case CityEditAction.Add:
        return AddCityLayout(
          l10n: l10n,
          cityNameController: _cityNameController,
          reasonController: _reasonTextController,
          currentCountry: _currentCountry,
          onCountryChanged: (CountryEntity newEntity) {
            setState(() {
              _currentCountry = newEntity;
            });
            _revalidateForm();
          },
        );
    }
  }

  String _getTitleKey() {
    switch (widget.action) {
      case CityEditAction.Edit:
        return 'title_edit';
      case CityEditAction.Remove:
        return 'title_remove';
      case CityEditAction.Add:
        return 'title_add';
    }
  }
}
