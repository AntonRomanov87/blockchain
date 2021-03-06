pragma solidity 0.4.23;

/* Общие замечания:
1. Используется очень старая версия компилятора
2. Не заблокирована возможность компилировать контракт на версиях 0.5.x и выше, необходимо проводить отдельные тесты на новых версиях
   прежде, чем разрешать компилировать контракт на них.
   Вообще рекомендуется прям жёстко задавать одну единственную версию: https://swcregistry.io/docs/SWC-103
3. Нет возможности поставить контракт на паузу в случае возникновения проблем.
4. Не видно, чтобы была продумана какая-то схема внесения изменений в контракт в случае если возникнут проблемы.
5. Контракт свободно может принимать платежи на свой счёт без каких-либо ивентов и без обработчиков этих платежей.
6. Предпочтительнее сделать админские функции multisig для большей безопасности, чтобы несколько админов должны были подтвердить добавление нового админа 
7. Контракт не сопровождается тестами с 100% покрытием кода.
8. Контракт неограниченно накапливает баланс, не продумана схема ограничения рисков (выведения излишней части токенов).
9. Абсолютно отсутствуют описания функций в коде и какие-либо комментарии.
10. Можно добавить функцию проверки целостности данных: например что сумма балансов в users_map равно балансу контракта и периодически её запускать
	и ставить на паузу контракт если что-то не так.
11. Не указан SPDX license identifier. В случае публикации кода контракта в etherscan могут быть неоднозначности в возможностях использования кода.
12. Необходимо устранить все ошибки которые выводит компилятор (тестировалось на 0.8.13):
	[Line 69] "message": ""now" has been deprecated. Use "block.timestamp" instead.",
	[Line 95] "message": ""send" and "transfer" are only available for objects of type "address payable", not "address".",
	[Line 1]  "message": "SPDX license identifier not provided in source file. Before publishing, consider adding a comment containing "SPDX-License-Identifier: <SPDX-License>" to each source file. Use "SPDX-License-Identifier: UNLICENSED" for non-open-source code. Please see https://spdx.org for more information.",
	[Line 49] "message": "Visibility for constructor is ignored. If you want the contract to be non-deployable, making it "abstract" is sufficient.",
 13. Проведён анализ через статический анализатор https://mythx.io/ - обнаруженные ошибки тоже занесены в комментарии.
 14. Запуск контракта и тестирование функций в dev-сети не проводилось, не хватило времени =))
 */

import "zeppelin-solidity/contracts/math/SafeMath.sol";

/*
TZ: contract creator becomes the first superuser. Then he adds new users and superusers. Every superuser can add new users and superusers;
If user sends ether, his balance is increased. Then he can withdraw eteher from his balance;
*/


contract VulnerableOne {
    using SafeMath for uint; // Далее в коде везде используются uint256, стоит явно указать что SafeMath для них, хоть это вроде и синонимы.
	// SafeMath не требуется начиная с Solidity 0.8.0, все underflow/overflow будут вызывать исключение автоматически.

    struct UserInfo {
        uint256 created;
		uint256 ether_balance;
		// Пользователь всё равно должен быть зарегистрирован, поэтому является ли он supseruser'ом можно было бы хранить и здесь,
		// чтобы не тратить storage-память на второй маппинг.
    }

    mapping (address => UserInfo) public users_map;
	mapping (address => bool) is_super_user; // https://swcregistry.io/docs/SWC-108 - необходимо явно указывать модификаторы видимости, по умолчанию получился internal
	address[] users_list; // аналогично
	
	modifier onlySuperUser() {
        require(is_super_user[msg.sender] == true);
        _;
    }

    event UserAdded(address new_user);

    constructor() public {
		set_super_user(msg.sender);
		add_new_user(msg.sender);
	}

	// Кто угодно может сделать себя superuser'ом, нет контроля доступа.
	function set_super_user(address _new_super_user) public {
		is_super_user[_new_super_user] = true;
		// Это критичное изменение состояния контракта, стоит логировать такие события через emit,
		// чтобы осущеставлять мониторинг безопасности и поставить контракт на паузу в случае неожиданностей.
	}
	// В ТЗ этого нет, но в целом может быть упущением отсутствие возможности удалить админа.

	// Нужно ли этому контракту самому себе вызывать pay? Скорее всего нет и лучше сделать модификатор external вместо public.
	function pay() public payable {
		require(users_map[msg.sender].created != 0);
		users_map[msg.sender].ether_balance += msg.value; // Операция без вызова .add из SafeMath
	}

	function add_new_user(address _new_user) public onlySuperUser {
		// Нет проверки на нулевой адрес 
		require(users_map[_new_user].created == 0); 
		emit UserAdded(_new_user); // может получиться, что закончится газ на выполнении функции, пользователь не добавится
			// а ивент отправится.
		users_map[_new_user] = UserInfo({ created: now, ether_balance: 0 });
		users_list.push(_new_user);
	}
	
	// Любой зарегистрирванный пользователь (не супер-пользователь) может удалить любого пользователя, нет контроля доступа, нужно добавить модификатор onlySuperUser
	function remove_user(address _remove_user) public {
		require(users_map[msg.sender].created != 0); // проверяется что пользователь-отправитель сообщения - зарегистрирован.
			// Надо ещё проверять, что удаляемый пользователь (_remove_user) - тоже зарегистрирован.
		delete(users_map[_remove_user]);
		bool shift = false;
		// Может закончиться газ в цикле если пользователей слишком много и функция перестанет работать. 
		for (uint i=0; i<users_list.length; i++) {
			if (users_list[i] == _remove_user) {
				shift = true;
			}
			if (shift == true) {
				users_list[i] = users_list[i+1]; // на последнем элементе массива попытаемся получить доступ к несщуествующему элементу и получим ошибку из-за этого
				// Плюс в итоге сам размер массива не уменьшится и в конце останется пустой элемент
			}
		}

		// Удаляемый пользователю не удаляется из is_super_user если он был супер-пользователем.
		// Плюс в ТЗ не сказано может ли суперпользователь удалить суперпользователя.
	}

	function withdraw() public {
		// Нет проверки что это зарегистрированный пользователь. По ТЗ только зарегистрированные пользователи могут снимать 
		// токены.

		// Нет проверки что у пользователя вообще есть какие-то токены на балансе.

		// Тут возможна атака reentrancy, необходимо в начале занулить баланс, а потом отправлять токены (Checks-Effects-Interactions паттерн).
        
		// msg.sender должен иметь fallback-функцию, чтобы принять transfer, иначе будет исключение. 
		// То есть кто угодно может в этот конракт отправить токены, но потом вернуть их может НЕ кто угодно.
		
		// Нужно поменять "msg.sender" на "payable(msg.sender)", чтобы не было ошибки компилятора.
		msg.sender.transfer(users_map[msg.sender].ether_balance); // стоит учитывать, что fallback-функция получит 
		    // ограниченное количество газа - всего 2300 и может не отработать.
			// Предпочтительнее использовать:
			//     (bool sent, ) = payable(msg.sender).call{value: amountToTransfer}(""); 
			//     require(sent);
			// чтобы тот кто вызывал контракт мог использовать весь газ, который он передал.

		users_map[msg.sender].ether_balance = 0; // незарегистрированный пользователь может прописаться в users_map
	}

	function get_user_balance(address _user) public view returns(uint256) {
		// В ТЗ явно не написано, может ли кто угодно запросить баланс кого угодно. 
		// На всякий случай стоило добавить проверку, что пользователь зарегистрирован.
		return users_map[_user].ether_balance;
	}

}
