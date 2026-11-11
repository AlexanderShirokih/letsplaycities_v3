import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_edit_actions_bloc.dart';
import 'package:lets_play_cities/base/cities_list/city_item.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/city_repository.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';
import 'package:lets_play_cities/screens/main/cites/list/widgets/add_city_layout.dart';
import 'package:lets_play_cities/screens/main/cites/list/widgets/remove_city_layout.dart';
import 'package:lets_play_cities/screens/main/cites/list/widgets/rename_city_layout.dart';

import '../model/city_edit_action.dart';

/// Screen that allows to send requests to edit, add or remove a city
class CityEditActionsScreen extends StatefulWidget {
  final CityEditAction action;
  final String? city;

  const CityEditActionsScreen({super.key, required this.action, this.city});

  @override
  State<CityEditActionsScreen> createState() => _CityEditActionsScreenState();
}

class _CityEditActionsScreenState extends State<CityEditActionsScreen> {
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
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      setState(() {
        final currentCityItem = CityItem(
          _cityNameController.text,
          _currentCountry ?? CountryEntity('', 0, false),
        );

        // All fields are filled
        final isFieldsFilled =
            _reasonTextController.text
                .replaceAll(RegExp(r'\s'), '')
                .isNotEmpty &&
            (widget.action == CityEditAction.remove ||
                (_cityNameController.text.isNotEmpty &&
                    _currentCountry != null));

        // Needs any changes to proceed
        final wantsChanges = widget.action == CityEditAction.edit;

        // Any changes was made
        final hasAnyChanges = _originalItem != currentCityItem;

        _showSendButton = isFieldsFilled && (hasAnyChanges || !wantsChanges);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocProvider<CityEditActionsBloc>(
      create: (context) => CityEditActionsBloc(
        GetIt.instance.get<CityRequestsRepository>(),
        GetIt.instance.get<CountryRepository>(),
        GetIt.instance.get<CityRepository>(),
        t.citiesList.unkCity,
        widget.city,
      ),
      child: Scaffold(
        body: BlocListener<CityEditActionsBloc, CityEditActionsState>(
          listener: (context, state) {
            if (state is CityNotFound) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.citiesRequest.cityNotFound(city: state.city)),
                ),
              );
            } else if (state is CityDataLoadingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.citiesRequest.formLoadingError)),
              );
            } else if (state is CityRequestSendingError) {
              final String message;
              switch (state.errorType) {
                case CityRequestSendingType.network:
                  message = t.citiesRequest.networkError;
                  break;
                case CityRequestSendingType.notAuthorized:
                  message = t.citiesRequest.signInToSend;
                  break;
                case CityRequestSendingType.rejected:
                  message = errorText(t, state.error!);
                  break;
              }

              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(message)));
            } else if (state is CityRequestSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.citiesRequest.requestSent)),
              );
              Navigator.pop(context);
            } else if (state is CityEditActionsData) {
              setState(() {
                _currentCountry ??= state.cityItem.country;
                _originalItem = state.cityItem;
              });
            }
          },
          child: SafeArea(
            child: Column(
              children: [
                AppScreenHeader(
                  title: _title(t),
                  onBack: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    child: _buildContent(context),
                  ),
                ),
                Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: AppButton(
                      label: t.citiesRequest.send,
                      icon: AppGlyph.send,
                      size: AppButtonSize.large,
                      expand: true,
                      onPressed: _showSendButton
                          ? () {
                              context.read<CityEditActionsBloc>().add(
                                CityEditActionSend(
                                  type: _mapType(widget.action),
                                  reason: _reasonTextController.text,
                                  updatedCityName: _cityNameController.text,
                                  updatedCountryCode:
                                      _currentCountry?.countryCode ?? 0,
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (widget.action) {
      case CityEditAction.edit:
        return RenameCityLayout(
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
      case CityEditAction.remove:
        return RemoveCityLayout(
          reasonController: _reasonTextController,
          onProposeEdit: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CityEditActionsScreen(
                action: CityEditAction.edit,
                city: widget.city,
              ),
            ),
          ),
        );
      case CityEditAction.add:
        return AddCityLayout(
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

  String _title(Translations t) => switch (widget.action) {
    CityEditAction.edit => t.citiesRequest.titleEdit,
    CityEditAction.remove => t.citiesRequest.titleRemove,
    CityEditAction.add => t.citiesRequest.titleAdd,
  };

  CityEditActionType _mapType(CityEditAction action) {
    switch (action) {
      case CityEditAction.edit:
        return CityEditActionType.edit;
      case CityEditAction.remove:
        return CityEditActionType.remove;
      case CityEditAction.add:
        return CityEditActionType.add;
    }
  }
}
