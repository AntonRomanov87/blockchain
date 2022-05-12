pragma solidity 0.4.23;

/* Общие замечания:
1. Используется очень старая версия компилятора
2. Не заблокирована возможность компилировать контракт на версиях 0.5.x и выше, необходимо проводить отдельные тесты на новых версиях
   прежде, чем разрешать компилировать контракт на них.
3. Нет возможности поставить контракт на паузу в случае возникновения проблем.
4. Не видно, чтобы была продумана какая-то схема внесения изменений в контракт в случае если возникнут проблемы.
5. Контракт свободно может принимать платежи на свой счёт без каких-либо ивентов и без обработчиков этих платежей.
6. Предпочтительнее сделать админские функции multisig для большей безопасности, чтобы несколько админов должны были подтвердить добавление нового админа 
7. Контракт не сопровождается тестами с 100% покрытием кода.
8. Контракт неограниченно накапливает баланс, не продумана схема ограничения рисков (выведения излишней части токенов).
9. Абсолютно отсутствуют описания функций в коде и какие-либо комментарии.
10. Можно добавить функцию проверки целостности данных: например что сумма балансов в users_map равно балансу контракта и периодически её запускать
	и ставить на паузу контракт если что-то не так.
 */

import "zeppelin-solidity/contracts/math/SafeMath.sol";

/*
TZ: contract creator becomes the first superuser. Then he adds new users and superusers. Every superuser can add new users and superusers;
If user sends ether, his balance is increased. Then he can withdraw eteher from his balance;
*/


contract VulnerableOne {
    using SafeMath for uint;

    struct UserInfo {
        uint256 created;
		uint256 ether_balance;
		// Пользователь всё равно должен быть зарегистрирован, поэтому является ли он supseruser'ом можно было бы хранить и здесь,
		// чтобы не тратить storage-память на второй маппинг.
    }

    mapping (address => UserInfo) public users_map;
	mapping (address => bool) is_super_user; // необходимо явно указывать модификаторы видимости, по умолчанию получился internal
	address[] users_list; // аналогично
	
	modifier onlySuperUser() {
        require(is_super_user[msg.sender] == true);
        _;
    }

    event UserAdded(address new_user); // забыли добавить emit на этот event в функцию add_new_user

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

	function pay() public payable {
		require(users_map[msg.sender].created != 0);
		users_map[msg.sender].ether_balance += msg.value;
	}

	function add_new_user(address _new_user) public onlySuperUser {
		require(users_map[_new_user].created == 0);
		users_map[_new_user] = UserInfo({ created: now, ether_balance: 0 });
		users_list.push(_new_user);
	}
	
	// Кто угодно может удалить пользователя, нет контроля доступа, нужно добавить модификатор onlySuperUser
	function remove_user(address _remove_user) public {
		require(users_map[msg.sender].created != 0); // проверяется что пользователь-отправитель сообщения есть в маппинге
			// По идее тут надо поправить на проверку существования _remove_user
		delete(users_map[_remove_user]); // потом удаляется совершенно другой пользователь (который передан как аргумент)
		bool shift = false;
		for (uint i=0; i<users_list.length; i++) {
			if (users_list[i] == _remove_user) {
				shift = true;
			}
			if (shift == true) {
				users_list[i] = users_list[i+1]; // на последнем элементе массива попытаемся получить доступ к несщуествующему элементу и получим ошибку из-за этого
				// Плюс в итоге сам размер массива не уменьшится и в конце останется пустой элемент
			}
		}
	}

	function withdraw() public {
		// Нет проверки что это зарегистрированный пользователь. По ТЗ только зарегистрированные пользователи могут снимать 
		// токены.

		// Тут возможна атака reentrancy, необходимо в начале занулить баланс, а потом отправлять токены (Checks-Effects-Interactions паттерн).
        msg.sender.transfer(users_map[msg.sender].ether_balance); // в случае если там принимает платежи какая-то функция-обработчик
			// стоит учитывать, что она получит ограниченное количество газа - всего 2300 и может не отработать.
			// Предпочтительнее использовать call, чтобы тот кто вызывал контракт мог использовать весь газ, который он передал.

		users_map[msg.sender].ether_balance = 0; // незарегистрированный пользователь может прописаться в users_map
	}

	function get_user_balance(address _user) public view returns(uint256) {
		// В ТЗ явно не написано, может ли кто угодно запросить баланс кого угодно. 
		// На всякий случай стоило добавить проверку, что пользователь зарегистрирован.
		return users_map[_user].ether_balance;
	}

}
