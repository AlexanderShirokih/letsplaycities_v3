import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/data/exceptions/exceptions.dart';
import 'package:lets_play_cities/presentation/states.dart';
import 'package:lets_play_cities/screens/common/error_handler_widget.dart';

typedef LoadingBuilder = Widget Function(BuildContext context, int? progress);
typedef DataBuilder<E> = Widget Function(BuildContext context, E data);
typedef ErrorBuilder = Widget Function(
    BuildContext context, BaseException error);

/// [BaseBlocBuilder] used to simplify boilerplate code while using BLoC.
/// This widget provides a collection of builders each used for particular state.
/// [initialBuilder] is used to build widgets on initial state or on custom state
/// if [builder] is not provided.
/// [dataBuilder] is used to build widgets when data is ready.
/// [loadingBuilder] is optional, and used to build layout on loading state.
/// [errorBuilder] is optional, and used to build layout on error state.
/// If [errorBuilder] is not provided, default error view will be used.
/// [builder] used to build layout on custom state (which not in the described above).
class BaseBlocBuilder<BlocClass extends Bloc<dynamic, BaseState<Entity>>,
    Entity> extends StatelessWidget {
  final WidgetBuilder initialBuilder;
  final DataBuilder<Entity> dataBuilder;

  final LoadingBuilder? loadingBuilder;
  final ErrorBuilder? errorBuilder;
  final BlocWidgetBuilder? builder;

  final BlocClass? bloc;

  const BaseBlocBuilder({
    Key? key,
    required this.initialBuilder,
    required this.dataBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.builder,
    this.bloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlocClass, BaseState<Entity>>(
      bloc: bloc,
      builder: (context, state) {
        if (state is InitialState<Entity>) {
          return initialBuilder(context);
        } else if (state is LoadingState<Entity>) {
          if (loadingBuilder != null) {
            return loadingBuilder!(context, state.progress);
          }
        } else if (state is ErrorState<Entity>) {
          if (errorBuilder != null) {
            return errorBuilder!(context, state.exception);
          }
          return ErrorHandlerView(
            state.exception.message ?? 'Unkonwn error',
            state.exception.stackTrace?.toString() ?? 'No stack trace provided',
          );
        } else if (state is DataState<Entity>) {
          return dataBuilder(context, state.data);
        }

        if (builder != null) {
          return builder!(context, state);
        }

        return initialBuilder(context);
      },
    );
  }
}
