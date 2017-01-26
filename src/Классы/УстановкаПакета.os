﻿#Использовать fs
#Использовать logos
#Использовать tempfiles

Перем Лог;
Перем мВременныйКаталогУстановки;
Перем мЗависимостиВРаботе;
Перем мРежимУстановкиПакетов;

Процедура УстановитьПакетИзАрхива(Знач ФайлАрхива) Экспорт
	
	Лог.Отладка("Устанавливаю пакет из архива: " + ФайлАрхива);
	Если мЗависимостиВРаботе = Неопределено Тогда
		мЗависимостиВРаботе = Новый Соответствие;
	КонецЕсли;
	
	мВременныйКаталогУстановки = ВременныеФайлы.СоздатьКаталог();
	Лог.Отладка("Временный каталог установки: " + мВременныйКаталогУстановки);
	
	Попытка
		
		Лог.Отладка("Открываем архив пакета");
		ЧтениеПакета = Новый ЧтениеZipФайла;
		ЧтениеПакета.Открыть(ФайлАрхива);
		
		ФайлСодержимого = ИзвлечьОбязательныйФайл(ЧтениеПакета, Константы.ИмяФайлаСодержимогоПакета);
		ФайлМетаданных  = ИзвлечьОбязательныйФайл(ЧтениеПакета, Константы.ИмяФайлаМетаданныхПакета);
		
		Метаданные = ПрочитатьМетаданныеПакета(ФайлМетаданных);
		ИмяПакета = Метаданные.Свойства().Имя;
		
		ПутьУстановки = НайтиСоздатьКаталогУстановки(ИмяПакета);
		Лог.Информация("Устанавливаю пакет " +  ИмяПакета);
		ПроверитьВерсиюСреды(Метаданные);
		Если мЗависимостиВРаботе[ИмяПакета] = "ВРаботе" Тогда
			ВызватьИсключение "Циклическая зависимость по пакету " + ИмяПакета;
		КонецЕсли;
		
		мЗависимостиВРаботе.Вставить(ИмяПакета, "ВРаботе");
		
		РазрешитьЗависимостиПакета(Метаданные);
		
		СтандартнаяОбработка = Истина;
		УстановитьФайлыПакета(ПутьУстановки, ФайлСодержимого, СтандартнаяОбработка);
		Если СтандартнаяОбработка Тогда
			СгенерироватьСкриптыЗапускаПриложенийПриНеобходимости(ПутьУстановки.ПолноеИмя, Метаданные);
		КонецЕсли;
		СохранитьФайлМетаданныхПакета(ПутьУстановки.ПолноеИмя, ФайлМетаданных);
		
		ЧтениеПакета.Закрыть();
		
		ВременныеФайлы.УдалитьФайл(мВременныйКаталогУстановки);
		
		мЗависимостиВРаботе.Вставить(ИмяПакета, "Установлен");
		
	Исключение
		ЧтениеПакета.Закрыть();
		ВременныеФайлы.УдалитьФайл(мВременныйКаталогУстановки);
		ВызватьИсключение;
	КонецПопытки;
	
	Лог.Информация("Установка завершена");
	
КонецПроцедуры

Процедура ПроверитьВерсиюСреды(Манифест)
	
	Свойства = Манифест.Свойства();
	Если НЕ Свойства.Свойство("ВерсияСреды") Тогда
		Возврат;
	КонецЕсли;
	
	ИмяПакета = Свойства.Имя;
	ТребуемаяВерсияСреды = Свойства.ВерсияСреды;
	СистемнаяИнформация = Новый СистемнаяИнформация;
	ВерсияСреды = СистемнаяИнформация.Версия;
	Если РаботаСВерсиями.СравнитьВерсии(ТребуемаяВерсияСреды, ВерсияСреды) > 0 Тогда
		ТекстСообщения = СтрШаблон(
		"Ошибка установки пакета <%1>: Обнаружена устаревшая версия движка OneScript.
		|Требуемая версия: %2
		|Текущая версия: %3
		|Обновите OneScript перед установкой пакета", 
		ИмяПакета,
		ТребуемаяВерсияСреды,
		ВерсияСреды
	);
	
	ВызватьИсключение ТекстСообщения;
КонецЕсли;

КонецПроцедуры

Процедура УстановитьПакетыПоОписаниюПакета() Экспорт
	
	ОписаниеПакета = РаботаСОписаниемПакета.ПрочитатьОписаниеПакета();
	
	ПроверитьВерсиюСреды(ОписаниеПакета);
	
	РазрешитьЗависимостиПакета(ОписаниеПакета);
	
КонецПроцедуры

Процедура УдалитьКаталогУстановкиПриОшибке(Знач Каталог)
	Лог.Отладка("Удаляю каталог " + Каталог);
	Попытка
		УдалитьФайлы(Каталог);
	Исключение
		Лог.Отладка("Не удалось удалить каталог " + Каталог + "
		|	- " + ОписаниеОшибки());
	КонецПопытки
КонецПроцедуры

Процедура УстановитьПакетИзОблака(Знач ИмяПакета) Экспорт
	
	ИмяВерсияПакета = РаботаСВерсиями.РазобратьИмяПакета(ИмяПакета);
	СкачатьИУстановитьПакет(ИмяВерсияПакета.ИмяПакета, ИмяВерсияПакета.Версия);
	
КонецПроцедуры

Процедура УстановитьВсеПакетыИзОблака() Экспорт
	
	КэшПакетовХаба = Новый КэшПакетовХаба();
	ПакетыХаба = КэшПакетовХаба.ПолучитьПакетыХаба();
	Для Каждого КлючИЗначение Из ПакетыХаба Цикл
		УстановитьПакетИзОблака(КлючИЗначение.Ключ);
	КонецЦикла;
	
КонецПроцедуры

Процедура ОбновитьПакетИзОблака(Знач ИмяПакета) Экспорт
	
	ИмяВерсияПакета = РаботаСВерсиями.РазобратьИмяПакета(ИмяПакета);
	СкачатьИУстановитьПакет(ИмяВерсияПакета.ИмяПакета, ИмяВерсияПакета.Версия);
	
КонецПроцедуры

Процедура ОбновитьУстановленныеПакеты() Экспорт
	КэшУстановленныхПакетов = Новый КэшУстановленныхПакетов;
	УстановленныеПакеты = КэшУстановленныхПакетов.ПолучитьУстановленныеПакеты();
	Для Каждого КлючИЗначение Из УстановленныеПакеты Цикл
		ОбновитьПакетИзОблака(КлючИЗначение.Ключ);
	КонецЦикла;
КонецПроцедуры

Процедура УстановитьРежимУстановкиПакетов(Знач ЗначениеРежимУстановкиПакетов) Экспорт
	мРежимУстановкиПакетов = ЗначениеРежимУстановкиПакетов;
КонецПроцедуры

Функция НайтиСоздатьКаталогУстановки(Знач ИдентификаторПакета)
	
	Если мРежимУстановкиПакетов = РежимУстановкиПакетов.Локально Тогда
		КаталогБиблиотек = Константы.ЛокальныйКаталогУстановкиПакетов;
	ИначеЕсли мРежимУстановкиПакетов = РежимУстановкиПакетов.Глобально Тогда
		КаталогБиблиотек = КаталогСистемныхБиблиотек();
	Иначе
		ВызватьИсключение "Неизвестный режим установки пакетов <" + мРежимУстановкиПакетов + ">";
	КонецЕсли;
	ПутьУстановки = Новый Файл(ОбъединитьПути(КаталогБиблиотек, ИдентификаторПакета));
	Лог.Отладка("Путь установки пакета: " + ПутьУстановки.ПолноеИмя);
	
	Если Не ПутьУстановки.Существует() Тогда
		СоздатьКаталог(ПутьУстановки.ПолноеИмя);
	ИначеЕсли ПутьУстановки.ЭтоФайл() Тогда
		ВызватьИсключение "Не удалось создать каталог " + ПутьУстановки.ПолноеИмя;
	КонецЕсли;
	
	Возврат ПутьУстановки;
	
КонецФункции

Процедура РазрешитьЗависимостиПакета(Знач Манифест)
	
	Зависимости = Манифест.Зависимости();
	Если Зависимости.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;
	
	УстановленныеПакеты = ПолучитьУстановленныеПакеты();
	
	Для Каждого Зависимость Из Зависимости Цикл
		Лог.Информация("Устанавливаю зависимость: " + Зависимость.ИмяПакета);

		Если Не УстановленныеПакеты.ПакетУстановлен(Зависимость) Тогда
			// скачать
			// определить зависимости и так по кругу
			СкачатьИУстановитьПакетПоОписанию(Зависимость);
			УстановленныеПакеты.Обновить();
		Иначе
			Лог.Информация("" + Зависимость.ИмяПакета + " уже установлен. Пропускаем.");
			// считаем, что версия всегда подходит
		КонецЕсли;
		
	КонецЦикла;
	
КонецПроцедуры

Функция ПолучитьУстановленныеПакеты()
	Возврат Новый КэшУстановленныхПакетов();
КонецФункции

Процедура СкачатьИУстановитьПакетПоОписанию(Знач ОписаниеПакета)
	// TODO: Нужно скачивание конкретной версии по маркеру
	СкачатьИУстановитьПакет(ОписаниеПакета.ИмяПакета, ОписаниеПакета.МинимальнаяВерсия);
КонецПроцедуры

Процедура СкачатьИУстановитьПакет(Знач ИмяПакета, Знач ВерсияПакета)
	
	Если ВерсияПакета <> Неопределено Тогда
		ФайлПакета = ИмяПакета + "-" + ВерсияПакета + ".ospx";
	Иначе
		ФайлПакета = ИмяПакета + ".ospx";
	КонецЕсли;
	
	Сервер = НастройкиПриложения.НастройкаСервераУдаленногоХранилища().СерверУдаленногоХранилища;
	Ресурс = ОбъединитьПути(НастройкиПриложения.НастройкаСервераУдаленногоХранилища().ПутьВХранилище, ИмяПакета, ФайлПакета);
	Соединение = ИнициализироватьСоединение(Сервер);
	
	Запрос = Новый HTTPЗапрос(Ресурс);
	Лог.Информация("Скачиваю файл: " + ФайлПакета);
	
	Ответ  = Соединение.Получить(Запрос);
	Если Ответ.КодСостояния = 200 Тогда
		Лог.Отладка("Файл получен");
		ВремФайл = ОбъединитьПути(КаталогВременныхФайлов(), ФайлПакета);
		Ответ.ПолучитьТелоКакДвоичныеДанные().Записать(ВремФайл);
		Ответ.Закрыть();
		Лог.Отладка("Соединение закрыто");
		Попытка
			УстановитьПакетИзАрхива(ВремФайл);
			УдалитьФайлы(ВремФайл);
		Исключение
			УдалитьФайлы(ВремФайл);
			ВызватьИсключение;
		КонецПопытки;
	Иначе
		ТекстИсключения = СтрШаблон("Ошибка установки пакета %1 <%2>", ИмяПакета, Ответ.КодСостояния);
		Ответ.Закрыть();
		ВызватьИсключение ТекстИсключения;
	КонецЕсли;
	
КонецПроцедуры

Функция ИнициализироватьСоединение(Сервер) Экспорт
	
	НастройкиПрокси = НастройкиПриложения.Получить().Прокси;
	Если НастройкиПрокси.ИспользоватьПрокси = Истина Тогда
		Прокси = Новый ИнтернетПрокси(НастройкиПрокси.ПроксиПоУмолчанию);
		Если НастройкиПрокси.ПроксиПоУмолчанию = Ложь Тогда
			Прокси.Установить("http",НастройкиПрокси.Сервер,НастройкиПрокси.Порт,НастройкиПрокси.Пользователь,НастройкиПрокси.Пароль,НастройкиПрокси.ИспользоватьАутентификациюОС);
		КонецЕсли;	
		Соединение = Новый HTTPСоединение(Сервер,,,,Прокси);
	Иначе
		Соединение = Новый HTTPСоединение(Сервер);
	КонецЕсли;
	
	Возврат Соединение;
	
КонецФункции	

Функция РазобратьМаркерВерсии(Знач МаркерВерсии)
	
	Перем ИндексВерсии;
	
	Оператор = Лев(МаркерВерсии, 1);
	Если Оператор = "<" или Оператор = ">" Тогда
		ТестОператор = Сред(МаркерВерсии, 2, 1);
		Если ТестОператор = "=" Тогда
			ИндексВерсии = 3;
		Иначе
			ИндексВерсии = 2;
		КонецЕсли;
	ИначеЕсли Оператор = "=" Тогда
		ИндексВерсии = 2;
	ИначеЕсли Найти("0123456789", Оператор) > 0 Тогда
		ИндексВерсии = 1;
	Иначе
		ВызватьИсключение "Некорректно задан маркер версии";
	КонецЕсли;
	
	Если ИндексВерсии > 1 Тогда
		Оператор = Лев(МаркерВерсии, ИндексВерсии-1);
	Иначе
		Оператор = "";
	КонецЕсли;
	
	Версия = Сред(МаркерВерсии, ИндексВерсии);
	
	Возврат Новый Структура("Оператор,Версия", Оператор, Версия);
	
КонецФункции

Функция КаталогСистемныхБиблиотек()
	
	СистемныеБиблиотеки = ОбъединитьПути(КаталогПрограммы(), ПолучитьЗначениеСистемнойНастройки("lib.system"));
	Лог.Отладка("СистемныеБиблиотеки " + СистемныеБиблиотеки);
	Если СистемныеБиблиотеки = Неопределено Тогда
		ВызватьИсключение "Не определен каталог системных библиотек";
	КонецЕсли;
	
	Возврат СистемныеБиблиотеки;
	
КонецФункции

Процедура УстановитьФайлыПакета(Знач ПутьУстановки, Знач ФайлСодержимого, СтандартнаяОбработка)
	
	ЧтениеСодержимого = Новый ЧтениеZipФайла(ФайлСодержимого);
	Попытка	
		ИмяСкриптаУстановки = Константы.ИмяФайлаСкриптаУстановки;
		ЭлементСкриптаУстановки = ЧтениеСодержимого.Элементы.Найти(ИмяСкриптаУстановки);
		Если ЭлементСкриптаУстановки <> Неопределено Тогда
			Лог.Отладка("Найден скрипт установки пакета");
			
			ЧтениеСодержимого.Извлечь(ЭлементСкриптаУстановки, мВременныйКаталогУстановки, РежимВосстановленияПутейФайловZIP.НеВосстанавливать);
			Лог.Отладка("Компиляция скрипта установки пакета");
			ОбъектСкрипта = ЗагрузитьСценарий(ОбъединитьПути(мВременныйКаталогУстановки, ИмяСкриптаУстановки));
			
			ВызватьСобытиеПередУстановкой(ОбъектСкрипта, ЧтениеСодержимого, ПутьУстановки.ПолноеИмя, СтандартнаяОбработка);
			
			Если СтандартнаяОбработка Тогда
				
				Лог.Отладка("Устанавливаю файлы пакета из архива");
				ЧтениеСодержимого.ИзвлечьВсе(ПутьУстановки.ПолноеИмя);
				
				ВызватьСобытиеПриУстановке(ОбъектСкрипта, ПутьУстановки.ПолноеИмя, СтандартнаяОбработка);
				
			КонецЕсли;
		Иначе
			Лог.Отладка("Устанавливаю файлы пакета из архива");
			ЧтениеСодержимого.ИзвлечьВсе(ПутьУстановки.ПолноеИмя);
		КонецЕсли;
	Исключение
		ЧтениеСодержимого.Закрыть();
		ВызватьИсключение;
	КонецПопытки;
	
	ЧтениеСодержимого.Закрыть();
	
КонецПроцедуры

Процедура ВызватьСобытиеПередУстановкой(Знач ОбъектСкрипта, Знач АрхивПакета, Знач Каталог, СтандартнаяОбработка)
	Лог.Отладка("Вызываю событие ПередУстановкой");
	ОбъектСкрипта.ПередУстановкой(АрхивПакета, Каталог, СтандартнаяОбработка);
КонецПроцедуры

Процедура ВызватьСобытиеПриУстановке(Знач ОбъектСкрипта, Знач Каталог, СтандартнаяОбработка)
	Лог.Отладка("Вызываю событие ПриУстановке");
	ОбъектСкрипта.ПриУстановке(Каталог, СтандартнаяОбработка);
КонецПроцедуры

Процедура СгенерироватьСкриптыЗапускаПриложенийПриНеобходимости(Знач КаталогУстановки, Знач ОписаниеПакета)
	
	ИмяПакета = ОписаниеПакета.Свойства().Имя;
	
	Для Каждого ФайлПриложения Из ОписаниеПакета.ИсполняемыеФайлы() Цикл
		
		ИмяСкриптаЗапуска = ?(ПустаяСтрока(ФайлПриложения.ИмяПриложения), ИмяПакета, ФайлПриложения.ИмяПриложения);
		Лог.Информация("Регистрация приложения: " + ИмяСкриптаЗапуска);
		
		ОбъектФайл = Новый Файл(ОбъединитьПути(КаталогУстановки, ФайлПриложения.Путь));
		
		Если Не ОбъектФайл.Существует() Тогда
			Лог.Ошибка("Файл приложения " + ОбъектФайл.ПолноеИмя + " не существует");
			ВызватьИсключение "Некорректные данные в метаданных пакета";
		КонецЕсли;
		
		Если мРежимУстановкиПакетов = РежимУстановкиПакетов.Локально Тогда
			КаталогУстановкиСкриптовЗапускаПриложений = ОбъединитьПути(Константы.ЛокальныйКаталогУстановкиПакетов, "bin");
			ФС.ОбеспечитьКаталог(КаталогУстановкиСкриптовЗапускаПриложений);
			КаталогУстановкиСкриптовЗапускаПриложений = Новый Файл(КаталогУстановкиСкриптовЗапускаПриложений).ПолноеИмя;
		ИначеЕсли мРежимУстановкиПакетов = РежимУстановкиПакетов.Глобально Тогда
			КаталогУстановкиСкриптовЗапускаПриложений = КаталогПрограммы();
		Иначе
			ВызватьИсключение "Неизвестный режим установки пакетов <" + мРежимУстановкиПакетов + ">";
		КонецЕсли;
		
		СоздатьСкриптЗапуска(ИмяСкриптаЗапуска, ОбъектФайл.ПолноеИмя, КаталогУстановкиСкриптовЗапускаПриложений);
	КонецЦикла;
	
КонецПроцедуры

Процедура СоздатьСкриптЗапуска(Знач ИмяСкриптаЗапуска, Знач ПутьФайлаПриложения, Знач Каталог) Экспорт

	СИ = Новый СистемнаяИнформация();
	ЭтоWindows = Найти(СИ.ВерсияОС, "Windows") > 0;
	Если ЭтоWindows > 0 Тогда
		ФайлЗапуска = Новый ЗаписьТекста(ОбъединитьПути(Каталог, ИмяСкриптаЗапуска + ".bat"), "cp866");
		ФайлЗапуска.ЗаписатьСтроку("@oscript.exe """ + ПутьФайлаПриложения + """ %*");
		ФайлЗапуска.ЗаписатьСтроку("@exit /b %ERRORLEVEL%");
		ФайлЗапуска.Закрыть();
	КонецЕсли;

	Если (ЭтоWindows И НастройкиПриложения.Получить().СоздаватьShСкриптЗапуска) ИЛИ НЕ ЭтоWindows Тогда
		ПолныйПутьКСкриптуЗапуска = ОбъединитьПути(Каталог, ИмяСкриптаЗапуска);
		ФайлЗапуска = Новый ЗаписьТекста(ПолныйПутьКСкриптуЗапуска, КодировкаТекста.UTF8NoBOM);
		ФайлЗапуска.ЗаписатьСтроку("#!/bin/bash");
		СтрокаЗапуска = "oscript";
		Если ЭтоWindows Тогда
			СтрокаЗапуска = СтрокаЗапуска + " -encoding=utf-8 ";
		КонецЕсли;
		СтрокаЗапуска = СтрокаЗапуска + """" + ПутьФайлаПриложения + """ ""$@""";
		ФайлЗапуска.ЗаписатьСтроку(СтрокаЗапуска);
		ФайлЗапуска.Закрыть();

		Если НЕ ЭтоWindows Тогда
			ЗапуститьПриложение("chmod +x """ + ПолныйПутьКСкриптуЗапуска + """");
		КонецЕсли;
	КонецЕсли;

КонецПроцедуры

Функция ПрочитатьМетаданныеПакета(Знач ФайлМетаданных)
	
	Перем Метаданные;
	Лог.Отладка("Чтение метаданных пакета");
	Попытка
		Чтение = Новый ЧтениеXML;
		Чтение.ОткрытьФайл(ФайлМетаданных);
		Лог.Отладка("XML загружен");
		Сериализатор = Новый СериализацияМетаданныхПакета;
		Метаданные = Сериализатор.ПрочитатьXML(Чтение);
		
		Чтение.Закрыть();
	Исключение
		Чтение.Закрыть();
		ВызватьИсключение;
	КонецПопытки;
	Лог.Отладка("Метаданные прочитаны");
	
	Возврат Метаданные;
	
КонецФункции

Процедура СохранитьФайлМетаданныхПакета(Знач КаталогУстановки, Знач ПутьКФайлуМетаданных)
	
	ПутьСохранения = ОбъединитьПути(КаталогУстановки, Константы.ИмяФайлаМетаданныхПакета);
	ДанныеФайла = Новый ДвоичныеДанные(ПутьКФайлуМетаданных);
	ДанныеФайла.Записать(ПутьСохранения);
	
КонецПроцедуры

//////////////////////////////////////////////////////////////////////////////////
//

Функция ИзвлечьОбязательныйФайл(Знач Чтение, Знач ИмяФайла)
	Лог.Отладка("Извлечение: " + ИмяФайла);
	Элемент = Чтение.Элементы.Найти(ИмяФайла);
	Если Элемент = Неопределено Тогда
		ВызватьИсключение "Неверная структура пакета. Не найден файл " + ИмяФайла;
	КонецЕсли;
	
	Чтение.Извлечь(Элемент, мВременныйКаталогУстановки);
	
	Возврат ОбъединитьПути(мВременныйКаталогУстановки, ИмяФайла);
	
КонецФункции

Лог = Логирование.ПолучитьЛог("oscript.app.opm");
мРежимУстановкиПакетов = РежимУстановкиПакетов.Глобально;
